require 'puppet/provider/keystone'

Puppet::Type.type(:keystone_service).provide(
  :openstack,
  :parent => Puppet::Provider::Keystone
) do

  desc "Provider to manage keystone services."

  @credentials = Puppet::Provider::Openstack::CredentialsV3.new

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def create
    if resource[:type]
      properties = [resource[:type]]
      properties << '--name' << resource[:name]
      if resource[:description]
        properties << '--description' << resource[:description]
      end
      self.class.request('service', 'create', properties)
      @property_hash[:ensure] = :present
    else
      raise(Puppet::Error, 'The type is mandatory for creating a keystone service')
    end
  end

  def destroy
    self.class.request('service', 'delete', @property_hash[:id])
    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def description
    @property_hash[:description]
  end

  def description=(value)
    @property_flush[:description] = value
  end

  def type
    @property_hash[:type]
  end

  def type=(value)
    @property_flush[:type] = value
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
    options = []
    if @property_flush && !@property_flush.empty?
      options << "--description=#{resource[:description]}" if @property_flush[:description]
      options << "--type=#{resource[:type]}" if @property_flush[:type]
      self.class.request('service', 'set', [@property_hash[:id]] + options) unless options.empty?
      @property_flush.clear
    end
  end
end
