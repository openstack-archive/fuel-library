require File.join(File.dirname(__FILE__), '..','..','..','puppet/provider/ovs_base')

Puppet::Type.type(:l2_bridge).provide(:ovs, :parent => Puppet::Provider::Ovs_base) do
  commands   :vsctl   => 'ovs-vsctl',
             :brctl   => 'brctl',
             :iproute => 'ip'

  def self.skip_port_for?(port_props)
    port_props[:br_type] != 'ovs'
  end

  def self.get_instances(big_hash)
    big_hash[:bridge]
  end

  # def self.instances
  #   rv = super
  #   #debug("#{rv.inspect}")
  # end

  #-----------------------------------------------------------------

  def create
    debug("CREATE resource: #{@resource}")
    @old_property_hash = {}
    @property_flush = {}.merge! @resource
    #
    vsctl('add-br', @resource[:bridge])
    iproute('link', 'set', 'up', 'dev', @resource[:bridge])
    notice("bridge '#{@resource[:bridge]}' created.")
    # We do self.attr_setter=(value) instead of attr=value because this doesn't
    # work in Puppet (our guess).
    # TODO (adanin): Fix other places like this one. See bug #1366009
    # self.external_ids=(@resource[:external_ids]) if @resource[:external_ids]
  end

  def destroy
    iproute('link', 'set', 'down', 'dev', @resource[:bridge])
    vsctl("del-br", @resource[:bridge])
  end

  def flush
    if @property_flush
      debug("FLUSH properties: #{@property_flush}")
      #
      # FLUSH changed properties
      if @property_flush.has_key? :stp
        vsctl('set', 'Bridge', @resource[:bridge], "stp_enable=#{@property_flush[:stp]}")
      end
      if @property_flush.has_key? :external_ids
        old_ids = (@old_property_hash[:external_ids] || {})
        new_ids = @property_flush[:external_ids]

        new_ids.each_pair do |k,v|
          if !  old_ids.has_key?(k)
            vsctl("br-set-external-id", @resource[:bridge], k, v)
          end
        end
      end
      #
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
    # result = vsctl("br-get-external-id", @resource[:bridge])
    vs = (@property_hash[:vendor_specific] || {})
    result = (vs[:external_ids] || '')
    return result #.split("\n").join(",")
  end
  def external_ids=(val)
    @property_flush[:external_ids] = val
  end

  def vendor_specific
    @property_hash[:vendor_specific] || :absent
  end
  def vendor_specific=(val)
    @property_flush[:vendor_specific] = val
  end

  def stp
    @property_hash[:stp] || :absent
  end
  def stp=(val)
    @property_flush[:stp] = val
  end

  #-----------------------------------------------------------------

  def _split(string, splitter=",")
    return Hash[string.split(splitter).map{|i| i.split("=")}]
  end

end
# vim: set ts=2 sw=2 et :