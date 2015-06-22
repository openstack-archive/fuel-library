require 'puppet/provider/keystone'

Puppet::Type.type(:keystone_endpoint).provide(
  :openstack,
  :parent => Puppet::Provider::Keystone
) do

  desc "Provider to manage keystone endpoints."

  @credentials = Puppet::Provider::Openstack::CredentialsV2_0.new

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def create
    properties = []
    # The region property is just ignored. We should fix this in kilo.
    region, name = resource[:name].split('/')
    properties << name
    properties << '--region'
    properties << region
    if resource[:public_url]
      properties << '--publicurl'
      properties << resource[:public_url]
    end
    if resource[:internal_url]
      properties << '--internalurl'
      properties << resource[:internal_url]
    end
    if resource[:admin_url]
      properties << '--adminurl'
      properties << resource[:admin_url]
    end
     self.class.request('endpoint', 'create', properties)
     @property_hash[:ensure] = :present
  end

  def destroy
    self.class.request('endpoint', 'delete', @property_hash[:id])
    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def region
    @property_hash[:region]
  end

  def public_url=(value)
    @property_flush[:public_url] = value
  end

  def public_url
    @property_hash[:public_url]
  end

  def internal_url=(value)
    @property_flush[:internal_url] = value
  end

  def internal_url
    @property_hash[:internal_url]
  end

  def admin_url=(value)
    @property_flush[:admin_url] = value
  end

  def admin_url
    @property_hash[:admin_url]
  end

  def id
    @property_hash[:id]
  end

  def self.instances
    list = request('endpoint', 'list', '--long')
    list.collect do |endpoint|
      new(
        :name         => "#{endpoint[:region]}/#{endpoint[:service_name]}",
        :ensure       => :present,
        :id           => endpoint[:id],
        :region       => endpoint[:region],
        :public_url   => endpoint[:publicurl],
        :internal_url => endpoint[:internalurl],
        :admin_url    => endpoint[:adminurl]
      )
    end
  end

  def self.prefetch(resources)
    endpoints = instances
    resources.keys.each do |name|
       if provider = endpoints.find{ |endpoint| endpoint.name == name }
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
