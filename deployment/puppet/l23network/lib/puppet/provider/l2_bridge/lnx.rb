require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/lnx_base')

Puppet::Type.type(:l2_bridge).provide(:lnx, :parent => Puppet::Provider::Lnx_base) do
  defaultfor :osfamily => :linux
  commands   :brctl   => 'brctl',
             :vsctl   => 'ovs-vsctl',
             :iproute => 'ip'


  def self.prefetch(resources)
    interfaces = instances
    resources.keys.each do |name|
      if provider = interfaces.find{ |ii| ii.name == name }
        resources[name].provider = provider
      end
    end
  end

  def self.instances
    rv = []
    get_bridge_list().each_pair do |bridge, props|
      rv << new({
        :ensure       => :present,
        :name         => bridge,
        :br_type      => props[:br_type],
        :external_ids => :absent
      }) if props[:br_type] == :lnx
    end
    rv
  end

  def exists?
    brctl('show', @resource[:bridge]).split(/\n+/).select{|v| v=~/^#{@resource[:bridge]}\s+\d+/}.size > 0  ?  true  :  false
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
      # if ! @property_flush[:mtu].nil?
      #   File.open("/sys/class/net/#{@resource[:interface]}/mtu", "w") { |f| f.write(@property_flush[:mtu]) }
      # end
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
    nil
  end
  #-----------------------------------------------------------------


end
# vim: set ts=2 sw=2 et :