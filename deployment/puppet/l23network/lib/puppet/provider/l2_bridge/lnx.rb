# Native linux bridging implementation
# Inspired by:
#  * https://www.kernel.org/doc/Documentation/networking/bridge.txt
#  * http://www.linuxfoundation.org/collaborate/workgroups/networking/bridge
#

require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/lnx_base')

Puppet::Type.type(:l2_bridge).provide(:lnx, :parent => Puppet::Provider::Lnx_base) do
  defaultfor :kernel    => :linux
  commands   :ethtool_cmd => 'ethtool'

  def self.instances
    rv = []
    get_bridge_list().each_pair do |bridge, props|
      debug("prefetching '#{bridge}'")
      br_props = {
        :ensure          => :present,
        :name            => bridge,
      }
      br_props.merge! props
      if props[:br_type] == :lnx
        #br_props[:provider] = 'lnx'
        #props[:port_type] = props[:port_type].insert(0, 'ovs').join(':')
        rv << new(br_props)
        debug("PREFETCH properties for '#{bridge}': #{br_props}")
      else
        debug("SKIP properties for '#{bridge}': #{br_props}")
      end
    end
    rv
  end

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource
    begin
      self.class.brctl(['addbr', @resource[:bridge]])
    rescue
      # Some time interface may be created by OS init scripts. It's a normal for Ubuntu.
      raise if ! self.class.iface_exist? @resource[:bridge]
      notice("'#{@resource[:bridge]}' already created by ghost event.")
    end
    self.class.interface_up(@resource[:bridge])
  end

  def destroy
    self.class.interface_down(@resource[:bridge])
    self.class.brctl(['delbr', @resource[:bridge]])
  end

  def flush
    if ! @property_flush.empty?
      debug("FLUSH properties: #{@property_flush}")
      #
      # FLUSH changed properties
      if @property_flush.has_key? :stp
        effective_stp = (@property_flush[:stp].to_s == 'true'  ?  1  :  0)
        File.open("/sys/class/net/#{@resource[:bridge]}/bridge/stp_state", "a") {|f| f << effective_stp}
      end
      @property_hash = resource.to_hash
    end
  end

  #-----------------------------------------------------------------
  def br_type
    @property_hash[:br_type] || :absent
  end
  def br_type=(val)
    @property_flush[:br_type] = val
  end

  # external IDs not supported
  def external_ids
    :absent
  end
  def external_ids=(value)
    {}
  end

  def stp
    # puppet has internal transformation, and we shouldn't use boolean values. Use symbols -- it works stable!!!
    @property_hash[:stp].to_s.to_sym
  end
  def stp=(val)
    @property_flush[:stp] = (val.to_s.downcase.to_sym==:true)
  end

  #-----------------------------------------------------------------


end
# vim: set ts=2 sw=2 et :
