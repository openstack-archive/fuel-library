$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', '..'))
require 'puppet/provider/keystone'
Puppet::Type.type(:keystone_endpoint).provide(
  :keystone,
  :parent => Puppet::Provider::Keystone
) do

  desc <<-EOT
    Provider that uses the keystone client tool to
    manage keystone endpoints

    This provider makes a few assumptions/
      1. assumes that the admin endpoint can be accessed via localhost.
      2. Assumes that the admin token and port can be accessed from
         /etc/keystone/keystone.conf
  EOT

  optional_commands :keystone => "keystone"

  def initialize(resource = nil)
    super(resource)
    @property_flush = {}
  end

  def self.prefetch(resources)
    endpoints = instances
    resources.keys.each do |name|
      if provider = endpoints.find{ |endpoint| endpoint.name == name }
        resources[name].provider = provider
      end
    end
  end

  def self.instances
    list_keystone_objects('endpoint', [5,6]).collect do |endpoint|
      service_name = get_keystone_object('service', endpoint[5], 'name')
      new(
        :name         => "#{endpoint[1]}/#{service_name}",
        :ensure       => :present,
        :id           => endpoint[0],
        :region       => endpoint[1],
        :public_url   => endpoint[2],
        :internal_url => endpoint[3],
        :admin_url    => endpoint[4],
        :service_id   => endpoint[5],
        :service_name => service_name
      )
    end
  end

  def create
    optional_opts = []
    {
      :public_url   => '--publicurl',
      :internal_url => '--internalurl',
      :admin_url    => '--adminurl'
    }.each do |param, opt|
      if resource[param]
        optional_opts.push(opt).push(resource[param])
      end
    end

    (region, service_name) = resource[:name].split('/')
    resource[:region] = region
    optional_opts.push('--region').push(resource[:region])

    service_id = self.class.list_keystone_objects('service', 4).detect do |s|
      s[1] == service_name
    end.first

    auth_keystone('endpoint-create', '--service-id', service_id, optional_opts)
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def destroy
    auth_keystone('endpoint-delete', @property_hash[:id])
  end

  def flush
    if ! @property_flush.empty?
      destroy
      create
      @property_flush.clear
    end
    @property_hash = resource.to_hash
  end

  def id
    @property_hash[:id]
  end

  def region
    @property_hash[:region]
  end

  def public_url
    @property_hash[:public_url]
  end

  def internal_url
    @property_hash[:internal_url]
  end

  def admin_url
    @property_hash[:admin_url]
  end

  def public_url=(value)
    @property_hash[:public_url] = value
    @property_flush[:public_url] = value
  end

  def internal_url=(value)
    @property_hash[:internal_url] = value
    @property_flush[:internal_url] = value
  end

  def admin_url=(value)
    @property_hash[:admin_url] = value
    @property_flush[:admin_url] = value
  end
end
