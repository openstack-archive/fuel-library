require 'puppet/provider/keystone'

Puppet::Type.type(:keystone_user).provide(
  :openstack,
  :parent => Puppet::Provider::Keystone
) do

  desc "Provider to manage keystone users."

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
    if resource[:password]
      properties << '--password' << resource[:password]
    end
    if resource[:tenant]
      properties << '--project' << resource[:tenant]
    end
    if resource[:email]
      properties << '--email' << resource[:email]
    end
    self.class.request('user', 'create', properties)
    @property_hash[:ensure] = :present
  end

  def destroy
    self.class.request('user', 'delete', @property_hash[:id])
    @property_hash.clear
  end

  def flush
    options = []
    if @property_flush && !@property_flush.empty?
      options << '--enable'  if @property_flush[:enabled] == :true
      options << '--disable' if @property_flush[:enabled] == :false
      # There is a --description flag for the set command, but it does not work if the value is empty
      options << '--password' << resource[:password] if @property_flush[:password]
      options << '--email'    << resource[:email]    if @property_flush[:email]
      # project handled in tenant= separately
      unless options.empty?
        options << @property_hash[:id]
        self.class.request('user', 'set', options)
      end
      @property_flush.clear
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  # Types properties
  def enabled
    bool_to_sym(@property_hash[:enabled])
  end

  def enabled=(value)
    @property_flush[:enabled] = value
  end

  def email
    @property_hash[:email]
  end

  def email=(value)
    @property_flush[:email] = value
  end

  def id
    @property_hash[:id]
  end

  def password
    res = nil
    return res if resource[:password] == nil
    if resource[:enabled] == :false || resource[:replace_password] == :false
      # Unchanged password
      res = resource[:password]
    else
      # Password validation
      credentials = Puppet::Provider::Openstack::CredentialsV2_0.new
      credentials.auth_url     = self.class.get_endpoint
      credentials.password     = resource[:password]
      credentials.project_name = resource[:tenant]
      credentials.username     = resource[:name]
      begin
        token = Puppet::Provider::Openstack.request('token', 'issue', ['--format', 'value'], credentials)
      rescue Puppet::Error::OpenstackUnauthorizedError
        # password is invalid
      else
        res = resource[:password] unless token.empty?
      end
    end
    return res
  end

  def password=(value)
    @property_flush[:password] = value
  end

  def replace_password
    @property_hash[:replace_password]
  end

  def replace_password=(value)
    @property_flush[:replace_password] = value
  end

  def tenant
    return resource[:tenant] if sym_to_bool(resource[:ignore_default_tenant])
    # use the one returned from instances
    tenant_name = @property_hash[:project]
    if tenant_name.nil? or tenant_name.empty?
      # if none (i.e. ldap backend) use the given one
      tenant_name = resource[:tenant]
    else
      return tenant_name
    end
    if tenant_name.nil? or tenant_name.empty?
      return nil # nothing found, nothing given
    end
    # If the user list command doesn't report the project, it might still be there
    # We don't need to know exactly what it is, we just need to know whether it's
    # the one we're trying to set.
    roles = self.class.request('user role', 'list', [resource[:name], '--project', tenant_name])
    if roles.empty?
      return nil
    else
      return tenant_name
    end
  end

  def tenant=(value)
    self.class.request('user', 'set', [resource[:name], '--project', value])
    rescue Puppet::ExecutionFailure => e
      if e.message =~ /You are not authorized to perform the requested action: LDAP user update/
        # read-only LDAP identity backend - just fall through
      else
        raise e
      end
      # note: read-write ldap will silently fail, not raise an exception
    else
    @property_hash[:tenant] = self.class.set_project(value, resource[:name])
  end

  def self.instances
    list = request('user', 'list', '--long')
    list.collect do |user|
      new(
        :name        => user[:name],
        :ensure      => :present,
        :enabled     => user[:enabled].downcase.chomp == 'true' ? true : false,
        :password    => user[:password],
        :project     => user[:project],
        :email       => user[:email],
        :id          => user[:id]
      )
    end
  end

  def self.prefetch(resources)
    users = instances
    resources.keys.each do |name|
       if provider = users.find{ |user| user.name == name }
        resources[name].provider = provider
      end
    end
  end

  def self.set_project(newproject, name)
    # some backends do not store the project/tenant in the user object, so we have to
    # to modify the project/tenant instead
    # First, see if the project actually needs to change
    roles = request('user role', 'list', [name, '--project', newproject])
    unless roles.empty?
      return # if already set, just skip
    end
    # Currently the only way to assign a user to a tenant not using user-create
    # is to use user-role-add - this means we also need a role - there is usual
    # a default role called _member_ which can be used for this purpose.  What
    # usually happens in a puppet module is that immediately after calling
    # keystone_user, the module will then assign a role to that user.  It is
    # ok for a user to have the _member_ role and another role.
    default_role = "_member_"
    begin
      request('role', 'show', [default_role])
    rescue
      debug("Keystone role #{default_role} does not exist - creating")
      request('role', 'create', [default_role])
    end
    request('role', 'add', [default_role, '--project', newproject, '--user', name])
  end
end
