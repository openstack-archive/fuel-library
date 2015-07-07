Puppet::Type.newtype(:ring_devices) do

  newparam(:name, :namevar => true) do
  end

  newparam(:storages) do
    desc 'list of all swift storages'

    validate do |value|
      if ! value.is_a? Hash
        fail(Puppet::Error, "#{value} should be a Hash of nodes with network roles to IP address mapping")
      end
    end

    munge do |value|
      value.values.each {|h| h['storage_address']=h['network_roles']['swift/replication'].gsub(/\/\d+$/,''); h.delete('network_roles')}
    end
  end

  autorequire(:ring_account_device) do
    autos = []
    catalog.resources.find_all { |r| r.is_a?(Puppet::Type.type("ring_account_device".to_sym)) }.each do |r|
      autos << r
    end
    autos
  end

  autorequire(:ring_object_device) do
    autos = []
    catalog.resources.find_all { |r| r.is_a?(Puppet::Type.type("ring_object_device".to_sym)) }.each do |r|
      autos << r
    end
    autos
  end

  autorequire(:ring_container_device) do
    autos = []
    catalog.resources.find_all { |r| r.is_a?(Puppet::Type.type("ring_container_device".to_sym)) }.each do |r|
      autos << r
    end
    autos
  end



  # Default resources for swift ring builder
  def resources
    resources = []

    default_storage = {
      'swift_zone' => 100,
      'object_port'=>6000,
      'container_port'=>6001,
      'account_port'=>6002,
      'mountpoints'=> "1 1\n2 1",
      'weight'=> 1,
      'types'=>['container', 'object', 'account'],
    }

    self[:storages].each do |storage|
      merged_storage = default_storage.merge(storage)
      merged_storage['types'].collect do |type|
        merged_storage['mountpoints'].split("\n").each do |mountpoint|
          port = merged_storage["#{type}_port"]
          device = mountpoint.split[0]
          options = {
            :name=>"#{merged_storage['storage_address']}:#{port}/#{device}",
            :zone => merged_storage['swift_zone'],
            :weight => merged_storage['weight'],
          }
          resources += [Puppet::Type.type("ring_#{type}_device".to_sym).new(options)]
        end
      end
    end
    resources
  end

  def eval_generate
    resources
  end



end
