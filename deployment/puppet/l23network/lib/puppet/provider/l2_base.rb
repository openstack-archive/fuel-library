require 'puppetx/l23_ethtool_name_commands_mapping'
require 'json'
require File.join(File.dirname(__FILE__), 'interface_toolset')

class Puppet::Provider::L2_base < Puppet::Provider::InterfaceToolset

  def self.prefetch(resources)
    interfaces = instances
    resources.keys.each do |name|
      if provider = interfaces.find{ |ii| ii.name == name }
        resources[name].provider = provider
      end
    end
  end

  # ---------------------------------------------------------------------------

  def self.get_lnx_vlan_interfaces
    # returns hash, that contains ports (interfaces) configuration.
    # i.e {
    #       eth0.101 => { :vlan_dev => 'eth0',  :vlan_id => 101, vlan_mode => 'eth' },
    #       vlan102  => { :vlan_dev => 'eth0',  :vlan_id => 102, vlan_mode => 'vlan' },
    #     }
    #
    vlan_ifaces = {}
    if File.exist? '/proc/net/vlan'
      rc_c = /([\w+\.\-]+)\s*\|\s*(\d+)\s*\|\s*([\w+\-]+)/
      File.open("/proc/net/vlan/config", "r").each do |line|
        if (rv=line.match(rc_c))
          vlan_ifaces[rv[1]] = {
            :vlan_dev  => rv[3],
            :vlan_id   => rv[2],
            :vlan_mode => (rv[1].match('\.').nil?  ?  'vlan'  :  'eth'  )
          }
        end
      end
    end
    return vlan_ifaces
  end

  def self.get_lnx_ports
    # returns hash, that contains ports (interfaces) configuration.
    # i.e {
    #       eth0 => { :mtu => 1500,  :if_type => :ethernet, port_type => lnx:eth:unremovable },
    #     }
    #
    # 'unremovable' flag for port_type means, that this port is a more complicated thing,
    # than just a port and can't be removed just as port. For example you can't remove bond
    #  as port. You should remove it as bond.
    #
    port = {}
    #
    # parse 802.1q vlan interfaces from /proc
    vlan_ifaces = self.get_lnx_vlan_interfaces()
    # Fetch information about interfaces, visible in network namespace from /sys/class/net
    interfaces = Dir['/sys/class/net/*'].select{ |f| File.symlink? f}
    interfaces.each do |if_dir|
      if_name = if_dir.split('/')[-1]
      port[if_name] = {
        :name         => if_name,
        :port_type    => [],
        :onboot       => self.get_iface_state(if_name),
        :ethtool      => nil,
        :peer_ifindex => nil,
        :ifindex      => File.open("#{if_dir}/ifindex").read.chomp.to_i,
        :mtu          => File.open("#{if_dir}/mtu").read.chomp.to_i,
        :provider     => (if_name == 'ovs-system')  ?  'ovs'  :  'lnx' ,
      }
      # determine port_type for this iface
      peer_ifindex = self.get_iface_peer_index(if_name)
      if !peer_ifindex.nil?
        port[if_name][:port_type] << 'jack' << 'unremovable'
        port[if_name][:peer_ifindex] = peer_ifindex
      elsif File.directory? "#{if_dir}/bonding"
        # This interface is a baster of bond, get bonding properties
        port[if_name][:slaves] = File.open("#{if_dir}/bonding/slaves").read.chomp.strip.split(/\s+/).sort
        port[if_name][:port_type] << 'bond' << 'unremovable'
      elsif File.directory? "#{if_dir}/bridge" and File.directory? "#{if_dir}/brif"
        # this interface is a bridge, get bridge properties
        port[if_name][:slaves] = Dir["#{if_dir}/brif/*"].map{|f| f.split('/')[-1]}.sort
        port[if_name][:port_type] << 'bridge' << 'unremovable'
      else
        #pass
      end
      # Check, whether this interface is a slave of anything
      if File.symlink?("#{if_dir}/master")
        port[if_name][:has_master] = File.readlink("#{if_dir}/master").split('/')[-1]
      end
      # Check, whether this interface is a subinterface
      if vlan_ifaces.has_key? if_name
        # this interface is a 802.1q subinterface
        port[if_name].merge! vlan_ifaces[if_name]
        port[if_name][:port_type] << 'vlan'
      end
    end
    # Check, whether port is a slave of anything another
    port.keys.each do |p_name|
      if port[p_name].has_key? :has_master
        master = port[p_name][:has_master]
        #debug("m='#{master}', name='#{p_name}', props=#{port[p_name]}")
        master_flags = port[master][:port_type]
        if master_flags.include? 'bond'
          # this port is a bond_member
          port[p_name][:bond_master] = master
          port[p_name][:port_type] << 'bond-slave'
        elsif master_flags.include? 'bridge'
          # this port is a member of bridge
          port[p_name][:bridge] = master
          port[p_name][:port_type] << 'bridge-slave'
        elsif master == 'ovs-system'
          port[p_name][:port_type] << 'ovs-affected'
        else
          #pass
        end
        port[p_name].delete(:has_master)
      end
    end
    return port
  end

  # ---------------------------------------------------------------------------
  def self.ovs_parse_opthash(hh)
    #if !(hh=~/^['"]/ and hh=~/['"]$/)
    rv = {}
    if hh =~ /^\{(.*)\}$/
      $1.split(/\s*\,\s*/).each do |pair|
        k,v = pair.split('=')
        #debug("===#{k}===#{v}===")
        rv[k.tr("'\"",'').to_sym] = v.nil?  ?  nil  :  v.tr("'\"",'')
      end
    end
    return rv
  end

  def self.get_ovs_bridges
    # return OVS interfaces hash if it possible

    vsctl_list_bridges = ovs_vsctl(['list', 'Bridge'])
    if vsctl_list_bridges.nil?
      debug("Can't find OVS ports, because error while 'ovs-vsctl list Bridge' execution")
      return {}
    end
    vsctl_list_bridges << :EOF  # last section of output should be processsed anyway.
    #
    buff = {}
    rv = {}
    # parse ovs-vsctl output and find OVS and OVS-affected interfaces
    vsctl_list_bridges.each do |line|
      if line =~ /(\w+)\s*\:\s*(.*)\s*$/
        key = $1.tr("'\"",'')
        val = $2.tr("'\"",'')
        buff[key] = (val == '[]'  ?  ''  :  val)
      elsif line =~ /^\s*$/ or line == :EOF
        stp_enable = buff['stp_enable'] || ''
        rv[buff['name']] = {
          :stp             => stp_enable.downcase == 'true',
          :vendor_specific => {
            :external_ids  => ovs_parse_opthash(buff['external_ids']),
            :other_config  => ovs_parse_opthash(buff['other_config']),
            :status        => ovs_parse_opthash(buff['status']),
            :datapath_type => buff['datapath_type'],
          }
        }
        debug("Found OVS br: '#{buff['name']}' with properties: #{rv[buff['name']]}")
        buff = {}
      else
        debug("Output of 'ovs-vsctl list Bridge' contain misformated line: '#{line}'")
      end
    end
    return rv
  end

  def self.get_ovs_ports
    # return OVS interfaces hash if it possible
    vsctl_list_ports = ovs_vsctl(['list', 'Port'])
    if vsctl_list_ports.nil?
      debug("Can't find OVS ports, because error while 'ovs-vsctl list Port' execution")
      return {}
    end
    vsctl_list_ports << :EOF  # last section of output should be processsed anyway.
    #
    buff = {}
    rv = {}
    # parse ovs-vsctl output and find OVS and OVS-affected interfaces
    vsctl_list_ports.each do |line|
      if line =~ /(\w+)\s*\:\s*(.*)\s*$/
        key = $1.tr("'\"",'')
        val = $2.tr("'\"",'')
        buff[key] = val == '[]'  ?  ''  :  val
      elsif line =~ /^\s*$/ or line == :EOF
        rv[buff['name']] = {
          :vendor_specific => {
            :other_config  => ovs_parse_opthash(buff['other_config']),
            :status        => ovs_parse_opthash(buff['status']),
          }
        }
        rv[buff['name']][:vlan_id] = buff['tag'] if ! (buff['tag'].nil? or buff['tag'].empty?)
        rv[buff['name']][:trunks]  = buff['trunks'].tr("[]",'').split(/[\,\s]+/) if ! (buff['trunks'].nil? or buff['trunks'].empty?)
        debug("Found OVS port '#{buff['name']}' with properties: #{rv[buff['name']]}")
        buff = {}
      else
        debug("Output of 'ovs-vsctl list Port' contain misformated line: '#{line}'")
      end
    end
    return rv
  end

  def self.get_ovs_interfaces
    # return OVS interfaces hash if it possible
    vsctl_list_interfaces = ovs_vsctl(['list', 'Interface'])
    if vsctl_list_interfaces.nil?
      debug("Can't find OVS interfaces, because error while 'ovs-vsctl list Interface' execution")
      return {}
    end
    vsctl_list_interfaces << :EOF  # last section of output should be processsed anyway.
    #
    buff = {}
    rv = {}
    # parse ovs-vsctl output and find OVS and OVS-affected interfaces
    vsctl_list_interfaces.each do |line|
      if line =~ /(\w+)\s*\:\s*(.*)\s*$/
        key = $1.tr("'\"",'')
        val = $2.tr("'\"",'')
        buff[key] = val == '[]'  ?  ''  :  val
      elsif line =~ /^\s*$/ or line == :EOF
        rv[buff['name']] = {
          :mtu        => buff['mtu'],
          :port_type  => (buff['type'].nil? or buff['type'].empty?)  ?  []  :  [buff['type']],
          :vendor_specific => {
            :status     => ovs_parse_opthash(buff['status']),
          }
        }
        driver = rv[buff['name']][:vendor_specific][:status][:driver_name]
        if driver.nil? or driver.empty? or driver == 'openvswitch'
            rv[buff['name']][:provider] = 'ovs'
        else
            rv[buff['name']][:provider] = nil
        end
        debug("Found OVS interface '#{buff['name']}' with properties: #{rv[buff['name']]}")
        buff = {}
      else
        debug("Output of 'ovs-vsctl list Interface' contain misformated line: '#{line}'")
      end
    end
    return rv
  end

  def self.ovs_vsctl_show
    content = ovs_vsctl('show')
    if content.nil?
      debug("Can't get OVS configuration, because error while 'ovs-vsctl show' execution")
      return {}
    end
    bridges = get_ovs_bridges()
    ports = get_ovs_ports()
    interfaces = get_ovs_interfaces()
    ovs_config = {
      :port      => {},
      :interface => {},
      #:bond      => {},  # bond in ovs is a internal only port !!!
      :bridge    => {},
      :jack      => {}  # jack of ovs patchcord (patchcord is a pair of ports with type 'patch')
    }
    _br = nil
    _po = nil
    _if = nil
    #_ift = nil
    content.each do |line|
      line.rstrip!
      case line
        when /^\s+Bridge\s+"?([\w\-\.]+)\"?$/
          _br = $1
          _po = nil
          _if = nil
          ovs_config[:bridge][_br] = {
            :port_type => ['bridge'],
            :br_type   => 'ovs',
            :provider  => 'ovs'
          }
          if bridges.has_key? _br
            ovs_config[:bridge][_br].merge! bridges[_br]
          end
        when /^\s+Port\s+"?([\w\-\.]+)\"?$/
          next if _br.nil?
          _po = $1
          _if = nil
          ovs_config[:port][_po] = {
            :bridge    => _br,
            :port_type => [],
            #:provider  => 'ovs'
          }
          if ports.has_key? _po
            ovs_config[:port][_po].merge! ports[_po]
          end
          if _po == _br
            ovs_config[:port][_po][:port_type] << 'bridge'
          end
        when /^\s+Interface\s+"?([\w\-\.]+)\"?$/
          _if = $1
          ovs_config[:interface][_if] = {
            :port => _po,
          }
          if interfaces.has_key? _if
            ovs_config[:interface][_if].merge! interfaces[_if]
          end
          #todo(sv): Check interface driver from Interfaces table
          ovs_config[:port][_po][:provider] = ovs_config[:interface][_if][:provider]
        when /^\s+type:\s+"?([\w\-\.]+)\"?$/
          ovs_config[:interface][_if].merge!({
            :type => $1
          })
        when /^\s+options:\s+\{(.+)\}\s*$/
          opts = $1.split(/[\s\,]+/).map{|o| o.split('=')}.reduce({}){|h,p| h.merge(p[0] => p[1].tr('"',''))}
          ovs_config[:interface][_if].merge!({
            :options => opts
          })
        else
          #debug("Misformated line for br='#{_br}', po='#{_po}', if='#{_if}' => '#{line}'")
      end
    end
    ovs_config[:port].keys.each do |p_name|
      # didn't use .select{...} here for backward compatibility with ruby 1.8
      ifaces = ovs_config[:interface].reject{|k,v| v[:port]!=p_name}
      iface = ifaces[ifaces.keys[0]]
      if ifaces.size > 1
        # Bond found
        #ovs_config[:bond][p_name] = ovs_config[:port][p_name]
        #ovs_config[:port].delete(p_name)
        ovs_config[:port][p_name][:port_type] << 'bond'
        ovs_config[:port][p_name][:provider] = 'ovs'
      elsif iface[:type] == 'patch'
        ovs_config[:port][p_name][:port_type] << 'jack'
      elsif iface[:type] == 'internal'
        ovs_config[:port][p_name][:port_type] << 'internal'
      else
        # ordinary interface found
        # pass
      end
      # get mtu value (from one of interfaces if bond) and up it to port layer
      k = ifaces.keys
      if k.size > 0
        ovs_config[:port][p_name][:mtu] = ifaces[k[0]][:mtu]
      end
      # fix port-type=vlan for tagged ports
      if !ovs_config[:port][p_name][:vlan_id].nil?
        ovs_config[:port][p_name][:port_type] << 'vlan'
      end
    end
    debug("VSCTL-SHOW: #{ovs_config.to_yaml.gsub('!ruby/sym ',':')}")
    return ovs_config
  end
  # ---------------------------------------------------------------------------

  def self.get_bridge_list
    # search all (LXN and OVS) bridges on the host, and return hash with mapping
    # bridge_name => { bridge options }
    #
    bridges = {}
    # obtain OVS bridges list
    re_c = /^\s*([\w\-]+)/
    listbr = ovs_vsctl('list-br')
    if listbr.nil?
      debug("No OVS bridges found, because error while 'ovs-vsctl list-br' execution")
    else
      listbr.select{|l| l.match(re_c)}.collect{|a| $1 if a.match(re_c)}.each do |br_name|
        br_name.strip!
        bridges[br_name] = {
          :br_type => :ovs
        }
      end
    end
    # obtain LNX bridges list
    re_c = /([\w\-]+)\s+\d+/
    begin
      # todo(sv): using port_list instead fork subprocess
      self.brctl(['show']).select{|l| l.match(re_c)}.collect{|a| $1 if a.match(re_c)}.each do |br_name|
        br_name.strip!
        bridges[br_name] = {
          :stp     => (File.open("/sys/class/net/#{br_name}/bridge/stp_state").read.strip.to_i == 1),
          :external_ids    => :absent,
          :vendor_specific => {},
          :br_type => :lnx
        }
      end
    rescue
      debug("No LNX bridges found, because error while 'brctl show' execution")
    end
    return bridges
  end

  def self.get_ovs_port_bridges_pairs
    # returns hash, which map ports to it's bridge.
    # i.e {
    #       qg37f65 => { :bridge => 'br-ex',  :br_type => :ovs },
    #     }
    #
    port_mappings = {}
    ovs_bridges = ovs_vsctl('list-br')
    if ovs_bridges.nil?
      debug("No OVS bridges found, because error while 'ovs-vsctl list-br' execution")
      return {}
    end
    ovs_bridges.select{|l| l.match(/^\s*[\w\-]+/)}.each do |br_name|
      br_name.strip!
      ovs_portlist = ovs_vsctl(['list-ports', br_name]).select{|l| l.match(/^\s*[\w\-]+\s*/)}
      #todo: handle error
      ovs_portlist.each do |port_name|
        port_name.strip!
        port_mappings[port_name] = {
          :bridge  => br_name,
          :br_type => :ovs
        }
      end
      # bridge also a port, but it don't show itself by list-ports, adding it manually
      port_mappings[br_name] = {
        :bridge  => br_name,
        :br_type => :ovs
      }
    end
    return port_mappings
  end

  def self.get_lnx_port_bridges_pairs
    # returns hash, which map ports to it's bridge.
    # i.e {
    #       'eth0' => { :bridge => 'br0',    :br_type => :lnx },
    #     }
    # This function returns all visible in default namespace ports
    # (lnx and ovs (with type internal)) included to the lnx bridge
    #
    begin
      brctl_show = self.brctl(['show']).split(/\n+/).select{|l| l.match(/^[\w\-]+\s+\d+/) or l.match(/^\s+[\w\.\-]+/)}
    rescue
      debug("No LNX bridges found, because error while 'brctl show' execution")
      return {}
    end
    port_mappings = {}
    br_name = nil
    brctl_show.each do |line|
      line.rstrip!
      case line
      when /^([\w\-]+)\s+[\d\.abcdef]+\s+(yes|no)\s+([\w\-\.]+$)/i
        br_name = $1
        port_name = $3
      when /^\s+([\w\.\-]+)$/
        #br_name using from previous turn
        port_name = $1
      else
        next
      end
      if br_name
        port_mappings[port_name] = {
          :bridge  => br_name,
          :br_type => :lnx
        }
      end
    end
    debug("LNX ports to bridges mapping: #{port_mappings.to_yaml.gsub('!ruby/sym ',':')}")
    return port_mappings
  end

  def self.get_port_bridges_pairs
    # returns hash, which map ports to it's bridge.
    # i.e {
    #       eth0    => { :bridge => 'br0',    :br_type => :lnx },
    #       qg37f65 => { :bridge => 'br-ex',  :br_type => :ovs },
    #     }
    # This function returns all visible in default namespace ports
    # (lnx and ovs (with type internal)) included to the lnx bridge
    #
    # If port included to both bridges (ovs and lnx at one time),
    # i.e. using as patchcord between bridges -- this port will be
    # assigned to lnx-type bridge
    #
    port_bridges_hash = self.get_ovs_port_bridges_pairs()       # LNX bridges should overwrite OVS
    port_bridges_hash.merge! self.get_lnx_port_bridges_pairs()  # because by design!
  end

  def self.get_bridges_order_for_patch(bridges)
    # if given two OVS bridges -- we should sort it by name
    # if given OVS and LNX bridges -- OVS should be first.
    br_type = []
    [0,1].each do |i|
      br_type << (File.directory?("/sys/class/net/#{bridges[i]}/bridge")  ?  'lnx'  :  'ovs' )
    end
    if br_type[0] == br_type[1]
      rv = bridges.sort()
    elsif br_type[0] == 'ovs'
      rv = [bridges[0],bridges[1]]
    else
      rv = [bridges[1],bridges[0]]
    end
    return rv
  end

  # ---------------------------------------------------------------------------

  def self.get_lnx_bonds
    # search all LXN bonds on the host, and return hash with
    # bond_name => { bond options }
    #
    bond = {}
    if File.exist?('/sys/class/net/bonding_masters')
      bondlist = File.open("/sys/class/net/bonding_masters").read.chomp.split(/\s+/).sort
    else
      return {}
    end
    bondlist.each do |bond_name|
      mode = File.open("/sys/class/net/#{bond_name}/bonding/mode").read.split(/\s+/)[0]
      bond[bond_name] = {
        :mtu     => File.open("/sys/class/net/#{bond_name}/mtu").read.chomp.to_i,
        :slaves  => File.open("/sys/class/net/#{bond_name}/bonding/slaves").read.chomp.split(/\s+/).sort,
        :bond_properties => {
          :mode             => mode,
          :miimon           => File.open("/sys/class/net/#{bond_name}/bonding/miimon").read.chomp,
          :updelay          => File.open("/sys/class/net/#{bond_name}/bonding/updelay").read.chomp,
          :downdelay        => File.open("/sys/class/net/#{bond_name}/bonding/downdelay").read.chomp,
        }
      }
      if ['802.3ad', 'balance-xor', 'balance-tlb', 'balance-alb'].include? mode
        xmit_hash_policy = File.open("/sys/class/net/#{bond_name}/bonding/xmit_hash_policy").read.split(/\s+/)[0]
        bond[bond_name][:bond_properties][:xmit_hash_policy] = xmit_hash_policy
      end
      if mode=='802.3ad'
        lacp_rate = File.open("/sys/class/net/#{bond_name}/bonding/lacp_rate").read.split(/\s+/)[0]
        ad_select = File.open("/sys/class/net/#{bond_name}/bonding/ad_select").read.split(/\s+/)[0],
        bond[bond_name][:bond_properties][:lacp_rate] = lacp_rate
        bond[bond_name][:bond_properties][:ad_select] = ad_select
      end
      bond[bond_name][:onboot] = !self.get_iface_state(bond_name).nil?
    end
    debug("get_lnx_bonds: LNX bond list #{bond}")
    return bond
  end

  def self.lnx_bond_allowed_properties
    {
      :active_slave      => {},
      :ad_select         => {},
      :all_slaves_active => {},
      :arp_interval      => {},
      :arp_ip_target     => {},
      :arp_validate      => {},
      :arp_all_targets   => {},
      :downdelay         => {},
      :updelay           => {},
      :fail_over_mac     => {},
      :lacp_rate         => {:need_reassemble => true},
      :miimon            => {},
      :min_links         => {},
      :mode              => {:need_reassemble => true},
      :num_grat_arp      => {},
      :num_unsol_na      => {},
      :packets_per_slave => {},
      :primary           => {},
      :primary_reselect  => {},
      :tlb_dynamic_lb    => {},
      :use_carrier       => {},
      :xmit_hash_policy  => {},
      :resend_igmp       => {},
      :lp_interval       => {}
    }
  end
  def self.lnx_bond_allowed_properties_list
    self.lnx_bond_allowed_properties.keys.sort
  end

  def self.get_ovs_bonds
    # search all OVS bonds on the host, and return hash with
    # bond_name => { bond options }
    all_ports_json = JSON.parse(ovs_vsctl(['-f json', 'list', 'port'])[0])
    all_ports_headings_to_data_hash = []
    all_ports_json['data'].each do | port |
      all_ports_headings_to_data_hash << Hash[all_ports_json['headings'].zip(port)]
    end

    bond_list = {}
    all_ports_headings_to_data_hash.each do | each_port |
      unless each_port['bond_active_slave'].is_a?(Array)
        bond_properties = {}
        bond_name = each_port['name']
        bond_list[bond_name] = {}
        self.ovs_bond_allowed_properties.each do | p_name, prop |
          transf_prop = prop[:property]
          get_value = ''
          get_value = prop[:default] if prop[:default]
          if transf_prop.match(%{config:})
            transf_prop = "#{transf_prop.split(':')[1]}"
            each_port['other_config'][1].each do |each_config|
              get_value = each_config[1] unless each_config.select{ |get_property| get_property == transf_prop }.empty?
            end
          else
            get_value = each_port[transf_prop] unless each_port[transf_prop].is_a?(Array)
          end
          get_value = prop[:override_integer].index(get_value) if prop[:override_integer]
          bond_properties[p_name] = get_value.to_s.gsub('"', '') unless get_value.to_s.empty?
        end
        slaves = []
        each_port['interfaces'][1].collect{ |int| int[1] }.each do | sl |
          slaves << ovs_vsctl(['get', 'interface', sl, 'name' ]).join().gsub('"', '')
        end
        bond_list[bond_name][:slaves] = slaves
        bond_list[bond_name][:bridge] = ovs_vsctl(['port-to-br', bond_name])[0]
        bond_list[bond_name][:bond_properties] = bond_properties
      end
    end
    debug("get_ovs_bonds: OVS bond list #{bond_list}")
    return bond_list
  end

  def self.ovs_bond_allowed_properties
    {
      :downdelay   => {:property => 'bond_downdelay'},
      :updelay     => {:property => 'bond_updelay'},
      :use_carrier => {:property => 'other_config:bond-detect-mode',
                       :default          => 'carrier',
                       :override_integer => ['miimon', 'carrier'], },
      :mode        => {:property => 'bond_mode',
                       :allow    => ['balance-slb', 'active-backup', 'balance-tcp', 'stable'],
                       :default  => 'active-backup' },
      :lacp        => {:property => 'lacp',
                       :allow    => ['off', 'active', 'passive'] },
      :lacp_rate   => {:property => 'other_config:lacp_time'},
      :miimon      => {:property => 'other_config:bond-miimon-interval'},
      :slb_rebalance_interval => {:property => 'other_config:bond-rebalance-interval'},
    }
  end
  def self.ovs_bond_allowed_properties_list
    self.ovs_bond_allowed_properties.keys.sort
  end

  # ---------------------------------------------------------------------------

  def self.get_ethtool_name_commands_mapping
    L23network.ethtool_name_commands_mapping
  end

  def self.get_iface_ethtool_hash(if_name, empty_return = {})
    tmp = {}
    #todo(sv): wrap to begin--resque
    ethtool_k = ethtool_cmd('-k', if_name)
    ethtool_k.split(/\n+/).select{|l| !l.match(/(^\s+|\[fixed\]|^Features)/)}.map{|x| x.split(/[\s\:]+/)}.each do |p|
      tmp[p[0]] = (p[1] == 'on')
    end
    return {
      'offload' => tmp || empty_return
    }
  end

  # ---------------------------------------------------------------------------

end

# vim: set ts=2 sw=2 et :
