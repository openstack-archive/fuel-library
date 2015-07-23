require 'puppet/provider/keystone'
require 'puppet/util/inifile'

Puppet::Type.type(:keystone_domain).provide(
  :openstack,
  :parent => Puppet::Provider::Keystone
) do

  desc 'Provider that manages keystone domains'

  @credentials = Puppet::Provider::Openstack::CredentialsV3.new

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
    @property_hash = self.class.request('domain', 'create', properties)
    @property_hash[:is_default] = sym_to_bool(resource[:is_default])
    @property_hash[:ensure] = :present
    ensure_default_domain(true)
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def destroy
    # have to disable first - Keystone does not allow you to delete an
    # enabled domain
    self.class.request('domain', 'set', [resource[:name], '--disable'])
    self.class.request('domain', 'delete', resource[:name])
    @property_hash[:ensure] == :absent
    ensure_default_domain(false, true)
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

  def is_default
    bool_to_sym(@property_hash[:is_default])
  end

  def is_default=(value)
    @property_flush[:is_default] = value
  end

  def ensure_default_domain(create, destroy=false, value=nil)
    if !self.class.keystone_file
      return
    end
    changed = false
    curid = self.class.default_domain_id
    newid = id
    default = (is_default == :true)
    if (default && create) || (!default && (value == :true))
      # new default domain, or making existing domain the default domain
      if curid != newid
        self.class.keystone_file['identity']['default_domain_id'] = newid
        changed = true
      end
    elsif (default && destroy) || (default && (value == :false))
      # removing default domain, or making this domain not the default
      if curid == newid
        # can't delete from inifile, so just reset to default 'default'
        self.class.keystone_file['identity']['default_domain_id'] = 'default'
        changed = true
        newid = 'default'
      end
    end
    if changed
      self.class.keystone_file.store
      debug("The default_domain_id was changed from #{curid} to #{newid}")
    end
  end

  def self.instances
    request('domain', 'list').collect do |domain|
      new(
        :name        => domain[:name],
        :ensure      => :present,
        :enabled     => domain[:enabled].downcase.chomp == 'true' ? true : false,
        :description => domain[:description],
        :id          => domain[:id],
        :is_default  => domain[:id] == default_domain_id
      )
    end
  end

  def self.prefetch(resources)
    domains = instances
    resources.keys.each do |name|
      if provider = domains.find{ |domain| domain.name == name }
        resources[name].provider = provider
      end
    end
  end

  def flush
    options = []
    if @property_flush && !@property_flush.empty?
      options << '--enable' if @property_flush[:enabled] == :true
      options << '--disable' if @property_flush[:enabled] == :false
      if @property_flush[:description]
        options << '--description' << resource[:description]
      end
      self.class.request('domain', 'set', [resource[:name]] + options) unless options.empty?
      if @property_flush[:is_default]
        ensure_default_domain(false, false, @property_flush[:is_default])
      end
      @property_flush.clear
    end
  end
end
