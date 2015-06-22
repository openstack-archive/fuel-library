require File.join(File.dirname(__FILE__), '..','..','..',
                  'puppet/provider/nova')

Puppet::Type.type(:nova_aggregate).provide(
  :nova,
  :parent => Puppet::Provider::Nova
) do

  desc "Manage nova aggregations"

  commands :nova => 'nova'

  mk_resource_methods

  def self.instances
    nova_aggregate_resources_ids().collect do |el|
      attrs = nova_aggregate_resources_attr(el['Id'])
      new(
          :ensure => :present,
          :name => attrs['Name'],
          :id => attrs['Id'],
          :availability_zone => attrs['Availability Zone'],
          :metadata => attrs['Metadata'],
          :hosts => attrs['Hosts']
          )
    end
  end

  def self.prefetch(resources)
    instances_ = instances
    resources.keys.each do |name|
      if provider = instances_.find{ |instance| instance.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def destroy
    #delete hosts first
    if not @property_hash[:hosts].nil?
      @property_hash[:hosts].each do |h|
        auth_nova("aggregate-remove-host", name, h)
      end
    end
    #now delete aggregate
    auth_nova("aggregate-delete", name)
    @property_hash[:ensure] = :absent
  end

  def create
    extras = Array.new
    #check for availability zone
    if not @resource[:availability_zone].nil? and not @resource[:availability_zone].empty?
      extras << "#{@resource[:availability_zone]}"
    end
    #run the command
    result = auth_nova("aggregate-create", resource[:name], extras)

    #get Id by Name
    id = self.class.nova_aggregate_resources_get_name_by_id(resource[:name])

    @property_hash = {
      :ensure => :present,
      :name => resource[:name],
      :id => id,
      :availability_zone => resource[:availability_zone]
      }

    #add metadata
    if not @resource[:metadata].nil? and not @resource[:metadata].empty?
      @resource[:metadata].each do |key, value|
        set_metadata_helper(id, key, value)
      end
      @property_hash[:metadata] = resource[:metadata]
    end

    #add hosts - This throws an error if the host is already attached to another aggregate!
    if not @resource[:hosts].nil? and not @resource[:hosts].empty?
      @resource[:hosts].each do |host|
        auth_nova("aggregate-add-host", id, "#{host}")
      end
      @property_hash[:hosts] = resource[:hosts]
    end
  end

  def hosts=(val)
    #get current hosts
    id = self.class.nova_aggregate_resources_get_name_by_id(name)
    attrs = self.class.nova_aggregate_resources_attr(id)
    #remove all hosts which are not in new value list
    attrs['Hosts'].each do |h|
      if not val.include? h
        auth_nova("aggregate-remove-host", id, "#{h}")
      end
    end

    #add hosts from the value list
    val.each do |h|
      if not attrs['Hosts'].include? h
        auth_nova("aggregate-add-host", id, "#{h}")
      end
    end
  end

  def set_metadata_helper(agg_id, key, value)
    auth_nova("aggregate-set-metadata", agg_id, "#{key}=#{value}")
  end

  def metadata
    #get current metadata
    id = self.class.nova_aggregate_resources_get_name_by_id(name)
    attrs = self.class.nova_aggregate_resources_attr(id)
    #just ignore the availability_zone. that's handled directly by nova
    attrs['Metadata'].delete('availability_zone')
    return attrs['Metadata']
  end

  def metadata=(val)
    #get current metadata
    id = self.class.nova_aggregate_resources_get_name_by_id(name)
    attrs = self.class.nova_aggregate_resources_attr(id)
    #get keys which are in current metadata but not in val. Make sure it has data first!
    if attrs['Metadata'].length > 0
      obsolete_keys = attrs['Metadata'].keys - val.keys
    end
    # clear obsolete keys. If there are any!
    if obsolete_keys
      obsolete_keys.each do |key|
        if not key.include? 'availability_zone'
          auth_nova("aggregate-set-metadata", id, "#{key}")
        end
      end
      #handle keys (with obsolete keys)
      new_keys = val.keys - obsolete_keys
    else
      #handle keys (without obsolete keys)
      new_keys = val.keys
    end
    #set new metadata if value changed
    new_keys.each do |key|
      if val[key] != attrs['Metadata'][key.to_s]
        value = val[key]
        set_metadata_helper(id, key, value)
      end
    end
  end

  def availability_zone=(val)
    id = self.class.nova_aggregate_resources_get_name_by_id(name)
    auth_nova("aggregate-set-metadata", id, "availability_zone=#{val}")
  end

end
