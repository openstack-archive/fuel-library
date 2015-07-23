require 'puppet/provider/keystone'

Puppet::Type.type(:keystone_user).provide(
  :openstack,
  :parent => Puppet::Provider::Keystone
) do

  desc "Provider to manage keystone users."

  @credentials = Puppet::Provider::Openstack::CredentialsV3.new

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def create
    # see if resource[:domain], or user specified as user::domain
    user_name, user_domain = self.class.name_and_domain(resource[:name], resource[:domain])
    properties = [user_name]
    if resource[:enabled] == :true
      properties << '--enable'
    elsif resource[:enabled] == :false
      properties << '--disable'
    end
    if resource[:password]
      properties << '--password' << resource[:password]
    end
    if resource[:email]
      properties << '--email' << resource[:email]
    end
    if user_domain
      properties << '--domain'
      properties << user_domain
    end
    @property_hash = self.class.request('user', 'create', properties)
    @property_hash[:domain] = user_domain
    if resource[:tenant]
      # DEPRECATED - To be removed in next release (Liberty)
      # https://bugs.launchpad.net/puppet-keystone/+bug/1472437
      project_id = Puppet::Resource.indirection.find("Keystone_tenant/#{resource[:tenant]}")[:id]
      set_project(resource[:tenant], project_id)
    end
    @property_hash[:ensure] = :present
  end

  def destroy
    self.class.request('user', 'delete', id)
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
      credentials                  = Puppet::Provider::Openstack::CredentialsV3.new
      credentials.auth_url         = self.class.get_endpoint
      credentials.password         = resource[:password]
      credentials.user_id          = id
      # NOTE: The only reason we use username is so that the openstack provider
      # will know we are doing v3password auth - otherwise, it is not used.  The
      # user_id uniquely identifies the user including domain.
      credentials.username, unused = self.class.name_and_domain(resource[:name], domain)
      # Need to specify a project id to get a project scoped token.  List
      # all of the projects for the user, and use the id from the first one.
      projects = self.class.request('project', 'list', ['--user', id, '--long'])
      if projects && projects[0] && projects[0][:id]
        credentials.project_id = projects[0][:id]
      else
        # last chance - try a domain scoped token
        credentials.domain_name = domain
      end
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

  def find_project_for_user(projname, project_id = nil)
    # DEPRECATED - To be removed in next release (Liberty)
    # https://bugs.launchpad.net/puppet-keystone/+bug/1472437
    user_name, user_domain = self.class.name_and_domain(resource[:name], resource[:domain])
    project_name, project_domain = self.class.name_and_domain(projname, nil, user_domain)
    self.class.request('project', 'list', ['--user', id, '--long']).each do |project|
      if (project_id == project[:id]) ||
         ((projname == project_name) && (project_domain == self.class.domain_name_from_id(project[:domain_id])))
        return project[:name]
      end
    end
    return nil
  end

  def set_project(newproject, project_id = nil)
    # DEPRECATED - To be removed in next release (Liberty)
    # https://bugs.launchpad.net/puppet-keystone/+bug/1472437
    unless project_id
      project_id = Puppet::Resource.indirection.find("Keystone_tenant/#{newproject}")[:id]
    end
    # Currently the only way to assign a user to a tenant not using user-create
    # is to use role-add - this means we also need a role - there is usual
    # a default role called _member_ which can be used for this purpose.  What
    # usually happens in a puppet module is that immediately after calling
    # keystone_user, the module will then assign a role to that user.  It is
    # ok for a user to have the _member_ role and another role.
    default_role = "_member_"
    begin
      self.class.request('role', 'show', default_role)
    rescue
      self.class.request('role', 'create', default_role)
    end
    # finally, assign the user to the project with the role
    self.class.request('role', 'add', [default_role, '--project', project_id, '--user', id])
    newproject
  end

  # DEPRECATED - To be removed in next release (Liberty)
  # https://bugs.launchpad.net/puppet-keystone/+bug/1472437
  def tenant=(value)
    @property_hash[:tenant] = set_project(value)
  end

  # DEPRECATED - To be removed in next release (Liberty)
  # https://bugs.launchpad.net/puppet-keystone/+bug/1472437
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
    project_id = Puppet::Resource.indirection.find("Keystone_tenant/#{tenant_name}")[:id]
    find_project_for_user(tenant_name, project_id)
  end

  def domain
    @property_hash[:domain]
  end

  def domain_id
    @property_hash[:domain_id]
  end

  def self.instances
    instance_hash = {}
    request('user', 'list', ['--long']).each do |user|
      # The field says "domain" but it is really the domain_id
      domname = domain_name_from_id(user[:domain])
      if instance_hash.include?(user[:name]) # not unique
        curdomid = instance_hash[user[:name]][:domain]
        if curdomid != default_domain_id
          # Move the user from the short name slot to the long name slot
          # because it is not in the default domain.
          curdomname = domain_name_from_id(curdomid)
          instance_hash["#{user[:name]}::#{curdomname}"] = instance_hash[user[:name]]
          # Use the short name slot for the new user
          instance_hash[user[:name]] = user
        else
          # Use the long name for the new user
          instance_hash["#{user[:name]}::#{domname}"] = user
        end
      else
        # Unique (for now) - store in short name slot
        instance_hash[user[:name]] = user
      end
    end
    instance_hash.keys.collect do |user_name|
      user = instance_hash[user_name]
      new(
        :name        => user_name,
        :ensure      => :present,
        :enabled     => user[:enabled].downcase.chomp == 'true' ? true : false,
        :password    => user[:password],
        :email       => user[:email],
        :description => user[:description],
        :domain      => domain_name_from_id(user[:domain]),
        :domain_id   => user[:domain],
        :id          => user[:id]
      )
    end
  end

  def self.prefetch(resources)
    users = instances
    resources.each do |resname, resource|
      # resname may be specified as just "name" or "name::domain"
      name, resdomain = name_and_domain(resname, resource[:domain])
      provider = users.find do |user|
        # have a match if the full instance name matches the full resource name, OR
        # the base resource name matches the base instance name, and the
        # resource domain matches the instance domain
        username, user_domain = name_and_domain(user.name, user.domain)
        (user.name == resname) ||
          ((username == name) && (user_domain == resdomain))
      end
      resource.provider = provider if provider
    end
  end

end
