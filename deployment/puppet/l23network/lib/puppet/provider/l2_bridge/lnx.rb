# Native linux bridging implementation
# Inspired by:
#  * https://www.kernel.org/doc/Documentation/networking/bridge.txt
#  * http://www.linuxfoundation.org/collaborate/workgroups/networking/bridge
#

require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/lnx_base')

Puppet::Type.type(:l2_bridge).provide(:lnx, :parent => Puppet::Provider::Lnx_base) do
  defaultfor :osfamily    => :linux
  commands   :brctl       => 'brctl',
             :ethtool_cmd => 'ethtool',
             :vsctl       => 'ovs-vsctl',
             :iproute     => 'ip'

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

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource
    brctl('addbr', @resource[:bridge])
    iproute('link', 'set', 'up', 'dev', @resource[:bridge])
    notice("bridge '#{@resource[:bridge]}' created.")
  end

  def destroy
    iproute('link', 'set', 'down', 'dev', @resource[:bridge])
    brctl('delbr', @resource[:bridge])
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
    @old_property_hash = {}
    @old_property_hash.merge! @property_hash
  end

  def flush
    if @property_flush
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