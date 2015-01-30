
class Puppet::Provider::L2_base < Puppet::Provider

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
        :name      => if_name,
        :port_type => [],
        :onboot    => self.get_iface_state(if_name),
        :mtu       => File.open("#{if_dir}/mtu").read.chomp,
        :provider  => (if_name == 'ovs-system')  ?  'ovs'  :  'lnx' ,
      }
      # determine port_type for this iface
      if File.directory? "#{if_dir}/bonding"
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
    begin
      vsctl_list_bridges = vsctl('list', 'Bridge').split("\n")
      vsctl_list_bridges << :EOF  # last section of output should be processsed anyway.
    rescue
      debug("Can't find OVS ports, because error while 'ovs-vsctl list Bridge' execution")
      return {}
    end
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
        rv[buff['name']] = {
          :stp             => buff['stp_enable'] == 'true',
          :vendor_specific => {
            :external_ids  => ovs_parse_opthash(buff['external_ids']),
            :other_config  => ovs_parse_opthash(buff['other_config']),
            :status        => ovs_parse_opthash(buff['status']),
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
    begin
      vsctl_list_ports = vsctl('list', 'Port').split("\n")
      vsctl_list_ports << :EOF  # last section of output should be processsed anyway.
    rescue
      debug("Can't find OVS ports, because error while 'ovs-vsctl list Port' execution")
      return {}
    end
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
            :trunks        => buff['trunks'].tr("[]",'').split(/[\,\s]+/), #.map{|i| i.to_i},
            :other_config  => ovs_parse_opthash(buff['other_config']),
            :status        => ovs_parse_opthash(buff['status']),
          }
        }
        rv[buff['name']][:vlan_id] = buff['tag'] if ! buff['tag'].empty?
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
    begin
      vsctl_list_interfaces = vsctl('list', 'Interface').split("\n")
      vsctl_list_interfaces << :EOF  # last section of output should be processsed anyway.
    rescue
      debug("Can't find OVS interfaces, because error while 'ovs-vsctl list Interface' execution")
      return {}
    end
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
          :port_type  => buff['type'].empty?  ?  []  :  [buff['type']],
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
    begin
      #content = vsctl('show')
      content = `ovs-vsctl show`
    rescue
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
    }
    _br = nil
    _po = nil
    _if = nil
    #_ift = nil
    content.split("\n").each do |line|
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
        else
          #debug("Misformated line for br='#{_br}', po='#{_po}', if='#{_if}' => '#{line}'")
      end
    end
    debug("VSCTL-SHOW: #{ovs_config.inspect}")
    ovs_config[:port].keys.each do |p_name|
      ifaces = ovs_config[:interface].select{|k,v| v[:port]==p_name}
      if ifaces.size > 1
        # Bond found
        #ovs_config[:bond][p_name] = ovs_config[:port][p_name]
        #ovs_config[:port].delete(p_name)
        ovs_config[:port][p_name][:port_type] << 'bond'
        ovs_config[:port][p_name][:provider] = 'ovs'
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
    begin
      vsctl('list-br').split(/\n+/).select{|l| l.match(re_c)}.collect{|a| $1 if a.match(re_c)}.each do |br_name|
        br_name.strip!
        bridges[br_name] = {
          :br_type => :ovs
        }
      end
    rescue
      debug("No OVS bridges found, because error while 'ovs-vsctl list-br' execution")
    end
    # obtain LNX bridges list
    re_c = /([\w\-]+)\s+\d+/
    begin
      brctl('show').split(/\n+/).select{|l| l.match(re_c)}.collect{|a| $1 if a.match(re_c)}.each do |br_name|
        br_name.strip!
        bridges[br_name] = {
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
    begin
      ovs_bridges = vsctl('list-br').split(/\n+/).select{|l| l.match(/^\s*[\w\-]+/)}
    rescue
      debug("No OVS bridges found, because error while 'ovs-vsctl list-br' execution")
      return {}
    end
    ovs_bridges.each do |br_name|
      br_name.strip!
      ovs_portlist = vsctl('list-ports', br_name).split(/\n+/).select{|l| l.match(/^\s*[\w\-]+\s*/)}
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
    #       eth0     => { :bridge => 'br0',    :br_type => :lnx },
    #     }
    # This function returns all visible in default namespace ports
    # (lnx and ovs (with type internal)) included to the lnx bridge
    #
    port_mappings = {}
    begin
      brctl_show = brctl('show').split(/\n+/).select{|l| l.match(/^[\w\-]+\s+\d+/) or l.match(/^\s+[\w\.\-]+/)}
    rescue
      debug("No LNX bridges found, because error while 'brctl show' execution")
      return {}
    end
    #todo: handle error
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

  # ---------------------------------------------------------------------------

  def self.get_lnx_bonds
    # search all LXN bonds on the host, and return hash with
    # bond_name => { bond options }
    #
    bond = {}
    bondlist = File.open("/sys/class/net/bonding_masters").read.chomp.split(/\s+/).sort
    bondlist.each do |bond_name|
      #bond_config = IO.readlines("/proc/net/bonding/#{bond_name}")
      bond[bond_name] = {
        :mtu             => File.open("/sys/class/net/#{bond_name}/mtu").read.chomp,
        :slaves           => File.open("/sys/class/net/#{bond_name}/bonding/slaves").read.chomp.split(/\s+/).sort,
        :bond_properties => {
          :mode             => File.open("/sys/class/net/#{bond_name}/bonding/mode").read.split(/\s+/)[0],
          :miimon           => File.open("/sys/class/net/#{bond_name}/bonding/miimon").read.chomp,
          #:xmit_hash_policy => File.open("/sys/class/net/#{bond_name}/bonding/xmit_hash_policy").read.split(/\s+/)[0],
          :lacp_rate        => File.open("/sys/class/net/#{bond_name}/bonding/lacp_rate").read.split(/\s+/)[0],
        }
      }
      bond[bond_name][:onboot] = !self.get_iface_state(bond_name).nil?
    end
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
      :updelay           => {},
      :use_carrier       => {},
      :xmit_hash_policy  => {},
      :resend_igmp       => {},
      :lp_interval       => {}
    }
  end
  def self.lnx_bond_allowed_properties_list
    self.lnx_bond_allowed_properties.keys.sort
  end


  def self.get_iface_state(iface)
    # returns:
    #    true  -- interface in UP state
    #    false -- interface in UP statu, but no-carrier
    #    nil   -- interface in DOWN state
    begin
      1 == File.open("/sys/class/net/#{iface}/carrier").read.chomp.to_i
    rescue
      # if interface is down, this file can't be read
      nil
    end
  end
end


# vim: set ts=2 sw=2 et :