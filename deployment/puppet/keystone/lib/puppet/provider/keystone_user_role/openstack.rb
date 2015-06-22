require 'puppet/provider/keystone'

Puppet::Type.type(:keystone_user_role).provide(
  :openstack,
  :parent => Puppet::Provider::Keystone
) do

  desc "Provider to manage keystone role assignments to users."

  @credentials = Puppet::Provider::Openstack::CredentialsV2_0.new

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def create
    properties = []
    properties << '--project' << get_project
    properties << '--user' << get_user
    if resource[:roles]
      resource[:roles].each do |role|
        self.class.request('role', 'add', [role] + properties)
      end
    end
  end

  def destroy
    properties = []
    properties << '--project' << get_project
    properties << '--user' << get_user
    if @property_hash[:roles]
      @property_hash[:roles].each do |role|
        self.class.request('role', 'remove', [role] + properties)
      end
    end
    @property_hash[:ensure] = :absent
  end

  def exists?
    if @user_role_hash
      return ! @property_hash[:name].empty?
    else
      roles = self.class.request('user role', 'list', [get_user, '--project', get_project])
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
      return @property_hash[:ensure] == :present
    end
  end

  def roles
    @property_hash[:roles]
  end

  def roles=(value)
    current_roles = roles
    # determine the roles to be added and removed
    remove = current_roles - Array(value)
    add    = Array(value) - current_roles
    user = get_user
    project = get_project
    add.each do |role_name|
      self.class.request('role', 'add', [role_name, '--project', project, '--user', user])
    end
    remove.each do |role_name|
      self.class.request('role', 'remove', [role_name, '--project', project, '--user', user])
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

  def get_user
    resource[:name].rpartition('@').first
  end

  def get_project
    resource[:name].rpartition('@').last
  end

  def self.get_projects
    request('project', 'list').collect { |project| project[:name] }
  end

  def self.get_users(project)
    request('user', 'list', ['--project', project]).collect { |user| user[:name] }
  end

  def self.set_user_role_hash(user_role_hash)
    @user_role_hash = user_role_hash
  end

  def self.build_user_role_hash
    hash = @user_role_hash || {}
    return hash unless hash.empty?
    projects = get_projects
    projects.each do |project|
      users = get_users(project)
      users.each do |user|
        user_roles = request('user role', 'list', [user, '--project', project])
        hash["#{user}@#{project}"] = []
        user_roles.each do |role|
          hash["#{user}@#{project}"] << role[:name]
        end
      end
    end
    set_user_role_hash(hash)
    hash
  end
end
