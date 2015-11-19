require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/lnx_base')

Puppet::Type.type(:l2_patch).provide(:lnx, :parent => Puppet::Provider::Lnx_base) do
  defaultfor :osfamily    => :linux
  commands   :brctl       => 'brctl'


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
    return patches #.map{|x| new(x)}
  end

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource
    # todo: divide simple creating interface and vlan
    begin
      self.class.iproute(['link', 'add', 'dev', @resource[:jacks][0], 'type', 'veth', 'peer', 'name', @resource[:jacks][1]])
    rescue
      # Some time interface may be created by OS init scripts. It's a normal for Ubuntu.
      raise if ! self.class.iface_exist? @resource[:interface]
      notice("'#{@resource[:interface]}' already created by ghost event.")
    end
  end

  def destroy
    debug("DESTROY resource: #{@resource}")
    self.class.iproute(['link', 'del', 'dev', @resource[:jacks][0], 'type', 'veth', 'peer', 'name', @resource[:jacks][1]])
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
