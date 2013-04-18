Puppet::Type.newtype(:ring_devices) do

  newparam(:name, :namevar => true) do
  end

  newparam(:storages) do
    desc "list of all swift storages"
  end

  def resources
    resources = []

    default_storage = {
      'zone' => 100,
      'object_port'=>6000,
      'container_port'=>6001,
      'account_port'=>6002,
      'mountpoints'=> "1 1\n2 1",
      'weight'=> 100,
      'types'=>['container', 'object', 'account'],
    }

    Puppet.notice("storages #{self[:storages].inspect}")

    storages = self[:storages]
    if storages.is_a? Hash
      storages = [storages]
    end

    storages.each do |storage|
      merged_storage = default_storage.merge(storage)
      merged_storage['types'].collect do |type|
        port = merged_storage["#{type}_port"]
        options = {
          :name=>"#{merged_storage['storage_local_net_ip']}:#{port}",
          :mountpoints=>merged_storage['mountpoints'],
          :zone=>merged_storage['zone']
        }
        resources += [Puppet::Type.type("ring_#{type}_device".to_sym).new(options)]
      end
    end
    resources
  end

  def generate
    resources
  end



end
