require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/lnx_base')

Puppet::Type.type(:l2_patch).provide(:lnx, :parent => Puppet::Provider::Lnx_base) do
  defaultfor :osfamily    => :linux


  def self.instances
    ports = get_lnx_ports()
    jacks = []
    ports.each_pair do |if_name, if_props|
      next unless if_props[:port_type].include? 'jack'
      jacks << {
        :name          => if_name,
        :bridge        => if_props[:bridge],
        :ifindex       => if_props[:ifindex],
        :peer_ifindex  => if_props[:peer_ifindex],
        :mtu           => if_props[:mtu],
        :provider      => 'lnx'
      }
    end

    # search pairs of jacks and make patchcord resources
    patches = []
    skip = []
    mtu = nil
    jacks.each do |jack|
      next if skip.include? jack[:name]
      # process patch between two bridges
      found_peer = jacks.select{|j| j[:ifindex]==jack[:peer_ifindex]}
      next if found_peer.empty?
      peer = found_peer[0]
      _bridges  = [jack[:bridge], peer[:bridge]].sort
      _tails    = ([jack[:bridge], peer[:bridge]] == _bridges  ?  [jack[:name], peer[:name]]  :  [peer[:name], jack[:name]])
      if _bridges.include? nil
        _name = "patch__raw__#{_tails[0]}--#{_tails[1]}"
      else
        _name = L23network.get_patch_name([jack[:bridge],peer[:bridge]])
      end
      props = {
        :ensure   => :present,
        :name     => _name,
        :bridges  => _bridges,
        :jacks    => _tails,
        :mtu      => mtu.to_s,
        :vlan_ids => ['0','0'], # because veth pairs can't be tagged
        :provider => 'ovs'
      }
      debug("PREFETCH properties for '#{props[:name]}': #{props}")
      patches << new(props)
      skip << peer[:name]
    end
    return patches
  end

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource
    patch_name = L23network.get_patch_name(@resource[:jacks])
    begin
      self.class.iproute(['link', 'add', 'dev', @resource[:jacks][0], 'type', 'veth', 'peer', 'name', @resource[:jacks][1]])
    rescue
      # Some time interface may be created by OS init scripts.
      raise unless self.class.iface_exist?(@resource[:jacks][0]) & self.class.iface_exist?(@resource[:jacks][1])
      notice("'#{patch_name}' is already created by ghost event.")
    end
    # plug-in jacks to bridges
    _bridges = self.class.get_bridge_list()
    self.class.get_bridges_order_for_patch(@resource[:bridges]).each_with_index do |br_name, i|
      _br = _bridges.fetch(br_name, {})
      #todo: sv: re-design for call method from bridge provider
      if _br[:br_type].to_s == 'lnx'
        self.class.iproute(['link', 'set', 'dev', @resource[:jacks][i], 'master', br_name ])
      elsif _br[:br_type].to_s == 'ovs'
        fail("lnx2ovs patchcord '#{patch_name}' is not implemented yet, use ovs2lnx for this purpose!")
        #self.class.ovs_vsctl(['--may-exist', 'add-port', br_name, @resource[:jacks][i]])
      end
    end
    # UP jacks
    @resource[:jacks].each do |jack_name|
      self.class.interface_up(jack_name, true)
    end
  end

  def destroy
    debug("DESTROY resource: #{@resource}")
    self.class.iproute(['link', 'del', 'dev', @resource[:jacks][0]])
  end

  def flush
    if !@property_flush.empty?
      debug("FLUSH properties: #{@property_flush}")
      if !['', 'absent'].include? @property_flush[:mtu].to_s
        # 'absent' is a synonym 'do-not-touch' for MTU
        @property_hash[:jacks].uniq.each do |iface|
          self.class.set_mtu(iface, @property_flush[:mtu])
        end
      end
      #todo: /sv: make ability of change bridges for RAW patchcords
      @property_hash = resource.to_hash
    end
  end

  #-----------------------------------------------------------------
  def bridges
    self.class.get_bridges_order_for_patch(@property_hash[:bridges])
  end
  def bridges=(val)
    @property_flush[:bridges] = self.class.get_bridges_order_for_patch(val)
  end

  def vlan_ids
    ['0', '0']
  end
  def vlan_ids=(val)
    warn("There are no ability for setup VLAN IDs for LNX-patchcords")
  end

  def mtu
    'absent'
  end
  def mtu=(val)
    @property_flush[:mtu] = val
  end

  def jacks
    @property_hash[:jacks]
  end
  def jacks=(val)
    nil
  end

  def cross
    nil
  end
  def cross=(val)
    nil
  end

end
# vim: set ts=2 sw=2 et :
