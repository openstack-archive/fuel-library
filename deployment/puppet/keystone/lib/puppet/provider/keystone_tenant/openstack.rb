require 'puppet/provider/keystone'

Puppet::Type.type(:keystone_tenant).provide(
  :openstack,
  :parent => Puppet::Provider::Keystone
) do

  desc "Provider to manage keystone tenants/projects."

  @credentials = Puppet::Provider::Openstack::CredentialsV2_0.new

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def create
    properties = [resource[:name]]
    if resource[:enabled] == :true
      properties << '--enable'
    elsif resource[:enabled] == :false
      properties << '--disable'
    end
    if resource[:description]
      properties << '--description'
      properties << resource[:description]
    end
     self.class.request('project', 'create', properties)
     @property_hash[:ensure] = :present
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def destroy
    self.class.request('project', 'delete', @property_hash[:id])
    @property_hash.clear
  end

  def enabled=(value)
    @property_flush[:enabled] = value
  end

  def enabled
    bool_to_sym(@property_hash[:enabled])
  end

  def description=(value)
    @property_flush[:description] = value
  end

  def description
    @property_hash[:description]
  end

  def id
    @property_hash[:id]
  end

  def self.instances
    list = request('project', 'list', '--long')
    list.collect do |project|
      new(
        :name        => project[:name],
        :ensure      => :present,
        :enabled     => project[:enabled].downcase.chomp == 'true' ? true : false,
        :description => project[:description],
        :id          => project[:id]
      )
    end
  end

  def self.prefetch(resources)
    tenants = instances
    resources.keys.each do |name|
       if provider = tenants.find{ |tenant| tenant.name == name }
        resources[name].provider = provider
      end
    end
  end

  def flush
    options = []
    if @property_flush && !@property_flush.empty?
      case @property_flush[:enabled]
      when :true
        options << '--enable'
      when :false
        options << '--disable'
      end
      (options << "--description=#{resource[:description]}") if @property_flush[:description]
      options << @property_hash[:id]
      self.class.request('project', 'set', options) unless options.empty?
      @property_flush.clear
    end
  end

end
