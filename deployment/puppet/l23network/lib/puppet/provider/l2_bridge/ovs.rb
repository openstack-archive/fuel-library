require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/lnx_base')

Puppet::Type.type(:l2_bridge).provide(:ovs, :parent => Puppet::Provider::Lnx_base) do
  commands   :vsctl   => 'ovs-vsctl',
             :brctl   => 'brctl',
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
        :ensure   => :present,
        :name     => bridge,
        :br_type  => props[:br_type],
      }) if props[:br_type] == :ovs
    end
    rv
  end
  #-----------------------------------------------------------------

  def exists?
    vsctl("br-exists", @resource[:bridge])
  rescue Puppet::ExecutionFailure
    return false
  end

  def create
    begin
      vsctl('br-exists', @resource[:bridge])
      if @resource[:skip_existing]
        notice("Bridge '#{@resource[:bridge]}' already exists, skip creating.")
        #external_ids = @resource[:external_ids] if @resource[:external_ids]
        return true
      else
        raise Puppet::ExecutionFailure, "Bridge '#{@resource[:bridge]}' already exists."
      end
    rescue Puppet::ExecutionFailure
      # pass
      notice("Bridge '#{@resource[:bridge]}' not exists, creating...")
    end
    vsctl('add-br', @resource[:bridge])
    iproute('link', 'set', 'up', 'dev', @resource[:bridge])
    notice("bridge '#{@resource[:bridge]}' created.")
    # We do self.attr_setter=(value) instead of attr=value because this doesn't
    # work in Puppet (our guess).
    # TODO (adanin): Fix other places like this one. See bug #1366009
    self.external_ids=(@resource[:external_ids]) if @resource[:external_ids]
  end

  def destroy
    iproute('link', 'set', 'down', 'dev', @resource[:bridge])
    vsctl("del-br", @resource[:bridge])
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

  def external_ids
    result = vsctl("br-get-external-id", @resource[:bridge])
    return result.split("\n").join(",")
  end
  def external_ids=(value)
    old_ids = _split(external_ids)
    new_ids = _split(value)

    new_ids.each_pair do |k,v|
      unless old_ids.has_key?(k)
        vsctl("br-set-external-id", @resource[:bridge], k, v)
      end
    end
  end
  #-----------------------------------------------------------------

  def _split(string, splitter=",")
    return Hash[string.split(splitter).map{|i| i.split("=")}]
  end

end
# vim: set ts=2 sw=2 et :