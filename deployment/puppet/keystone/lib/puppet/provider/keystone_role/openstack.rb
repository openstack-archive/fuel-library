require 'puppet/provider/keystone'

Puppet::Type.type(:keystone_role).provide(
  :openstack,
  :parent => Puppet::Provider::Keystone
) do

  desc 'Provider for keystone roles.'

  @credentials = Puppet::Provider::Openstack::CredentialsV3.new

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def create
    self.class.request('role', 'create', name)
    @property_hash[:ensure] = :present
  end

  def destroy
    self.class.request('role', 'delete', @property_hash[:id])
    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def id
    @property_hash[:id]
  end

  def self.instances
    list = request('role', 'list')
    list.collect do |role|
      new(
        :name        => role[:name],
        :ensure      => :present,
        :id          => role[:id]
      )
    end
  end

  def self.prefetch(resources)
    roles = instances
    resources.keys.each do |name|
       if provider = roles.find{ |role| role.name == name }
        resources[name].provider = provider
      end
    end
  end
end
