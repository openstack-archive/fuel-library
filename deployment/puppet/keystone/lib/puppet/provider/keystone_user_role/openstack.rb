require 'puppet/provider/keystone'
require 'puppet/provider/keystone/util'

Puppet::Type.type(:keystone_user_role).provide(
  :openstack,
  :parent => Puppet::Provider::Keystone
) do

  desc "Provider to manage keystone role assignments to users."

  @credentials = Puppet::Provider::Openstack::CredentialsV3.new

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def create
    if resource[:roles]
      resource[:roles].each do |role|
        self.class.request('role', 'add', [role] + properties)
      end
    end
  end

  def destroy
    if @property_hash[:roles]
      @property_hash[:roles].each do |role|
        self.class.request('role', 'remove', [role] + properties)
      end
    end
    @property_hash[:ensure] = :absent
  end

  def exists?
    if self.class.user_role_hash.nil? || self.class.user_role_hash.empty?
      roles = self.class.request('role', 'list', properties)
      # Since requesting every combination of users, roles, and
      # projects is so expensive, construct the property hash here
      # instead of in self.instances so it can be used in the role
      # and destroy methods
      @property_hash[:name] = resource[:name]
      if roles.empty?
        @property_hash[:ensure] = :absent
      else
        @property_hash[:ensure] = :present
        @property_hash[:roles]  = roles.collect do |role|
          role[:name]
        end
      end
    end
    return @property_hash[:ensure] == :present
  end

  def roles
    @property_hash[:roles]
  end

  def roles=(value)
    current_roles = roles
    # determine the roles to be added and removed
    remove = current_roles - Array(value)
    add    = Array(value) - current_roles
    add.each do |role_name|
      self.class.request('role', 'add', [role_name] + properties)
    end
    remove.each do |role_name|
      self.class.request('role', 'remove', [role_name] + properties)
    end
  end

  def self.instances
    instances = build_user_role_hash
    instances.collect do |title, roles|
      new(
        :name   => title,
        :ensure => :present,
        :roles  => roles
      )
    end
  end

  private

  def properties
    properties = []
    if get_project_id
      properties << '--project' << get_project_id
    elsif get_domain
      properties << '--domain' << get_domain
    else
      error("No project or domain specified for role")
    end
    properties << '--user' << get_user_id
    properties
  end

  def get_user
    resource[:name].rpartition('@').first
  end

  def get_project
    resource[:name].rpartition('@').last
  end

  # if the role is for a domain, it will be specified as
  # user@::domain - the "project" part will be empty
  def get_domain
    # use defined because @domain may be nil
    return @domain if defined?(@domain)
    projname, domname = Util.split_domain(get_project)
    if projname.nil?
      @domain = domname # no project specified, so must be a domain
    else
      @domain = nil # not a domain specific role
    end
    @domain
  end

  def get_user_id
    @user_id ||= Puppet::Resource.indirection.find("Keystone_user/#{get_user}")[:id]
  end

  def get_project_id
    # use defined because @project_id may be nil
    return @project_id if defined?(@project_id)
    projname, domname = Util.split_domain(get_project)
    if projname.nil?
      @project_id = nil
    else
      @project_id ||= Puppet::Resource.indirection.find("Keystone_tenant/#{get_project}")[:id]
    end
    @project_id
  end

  def self.get_projects
    request('project', 'list', '--long').collect do |project|
      {
        :id        => project[:id],
        :name      => project[:name],
        :domain_id => project[:domain_id],
        :domain    => domain_name_from_id(project[:domain_id])
      }
    end
  end

  def self.get_users(project_id=nil, domain_id=nil)
    properties = ['--long']
    if project_id
      properties << '--project' << project_id
    elsif domain_id
      properties << '--domain' << domain_id
    end
    request('user', 'list', properties).collect do |user|
      {
        :id        => user[:id],
        :name      => user[:name],
        # note - column is "Domain" but it is really the domain id
        :domain_id => user[:domain],
        :domain    => domain_name_from_id(user[:domain])
      }
    end
  end

  def self.user_role_hash
    @user_role_hash
  end

  def self.set_user_role_hash(user_role_hash)
    @user_role_hash = user_role_hash
  end

  def self.build_user_role_hash
    # The new hash will have the property that if the
    # given key does not exist, create it with an empty
    # array as the value for the hash key
    hash = @user_role_hash || Hash.new{|h,k| h[k] = []}
    return hash unless hash.empty?
    # Need a mapping of project id to names.
    project_hash = {}
    Puppet::Type.type(:keystone_tenant).provider(:openstack).instances.each do |project|
      project_hash[project.id] = project.name
    end
    # Need a mapping of user id to names.
    user_hash = {}
    Puppet::Type.type(:keystone_user).provider(:openstack).instances.each do |user|
      user_hash[user.id] = user.name
    end
    # need a mapping of role id to name
    role_hash = {}
    request('role', 'list').each {|role| role_hash[role[:id]] = role[:name]}
    # now, get all role assignments
    request('role assignment', 'list').each do |assignment|
      if assignment[:user]
        if assignment[:project]
          hash["#{user_hash[assignment[:user]]}@#{project_hash[assignment[:project]]}"] << role_hash[assignment[:role]]
        else
          domainname = domain_id_to_name(assignment[:domain])
          hash["#{user_hash[assignment[:user]]}@::#{domainname}"] << role_hash[assignment[:role]]
        end
      end
    end
    set_user_role_hash(hash)
    hash
  end
end
