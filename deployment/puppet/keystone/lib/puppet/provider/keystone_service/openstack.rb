require 'puppet/provider/keystone'

Puppet::Type.type(:keystone_service).provide(
  :openstack,
  :parent => Puppet::Provider::Keystone
) do

  desc "Provider to manage keystone services."

  @credentials = Puppet::Provider::Openstack::CredentialsV2_0.new

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def create
    properties = ['--name']
    properties << resource[:name]
    if resource[:description]
      properties << '--description'
      properties << resource[:description]
    end
    raise(Puppet::Error, 'The service type is mandatory') unless resource[:type]
    properties << resource[:type]
    self.class.request('service', 'create', properties)
    @property_hash[:ensure] = :present
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def destroy
    self.class.request('service', 'delete', @property_hash[:id])
    @property_hash.clear
  end

  def description=(value)
    @property_flush[:description] = value
  end

  def description
    @property_hash[:description]
  end

  def type=(value)
    @property_flush[:type] = value
  end

  def type
    @property_hash[:type]
  end

  def id
    @property_hash[:id]
  end

  def self.instances
    list = request('service', 'list', '--long')
    list.collect do |service|
      new(
        :name        => service[:name],
        :ensure      => :present,
        :type        => service[:type],
        :description => service[:description],
        :id          => service[:id]
      )
    end
  end

  def self.prefetch(resources)
    services = instances
    resources.keys.each do |name|
       if provider = services.find{ |service| service.name == name }
        resources[name].provider = provider
      end
    end
  end

  def flush
    if ! @property_flush.empty?
      destroy
      create
      @property_flush.clear
    end
  end
end
