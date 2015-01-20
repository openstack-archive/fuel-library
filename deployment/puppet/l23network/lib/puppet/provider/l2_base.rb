
class Puppet::Provider::L2_base < Puppet::Provider

  def self.get_bridge_list
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
    portlist = {}
    ovs_bridges = vsctl('list-br').split(/\n+/).select{|l| l.match(/^\s*[\w\-]+/)}
    #todo: handle error
    ovs_bridges.each do |br_name|
      br_name.strip!
      ovs_portlist = vsctl('list-ports', br_name).split(/\n+/).select{|l| l.match(/^\s*[\w\-]+\s*/)}
      #todo: handle error
      ovs_portlist.each do |port_name|
        port_name.strip!
        portlist[port_name] = {
          :bridge  => br_name,
          :br_type => :ovs
        }
      end
      # bridge also a port, but it don't show itself by list-ports
      portlist[br_name] = {
        :bridge  => br_name,
        :br_type => :ovs
      }
    end
    return portlist
  end

  def self.get_lnx_port_bridges_pairs
    portlist = {}
    brctl_show = brctl('show').split(/\n+/).select{|l| l.match(/^[\w\-]+\s+\d+/) or l.match(/^\s+[\w\.\-]+/)}
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
        portlist[port_name] = {
          :bridge  => br_name,
          :br_type => :lnx
        }
      end
    end
    return portlist
  end

  def self.get_lnx_bonds
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