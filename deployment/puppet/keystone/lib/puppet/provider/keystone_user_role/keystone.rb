$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', '..'))
require 'puppet/provider/keystone'
Puppet::Type.type(:keystone_user_role).provide(
  :keystone,
  :parent => Puppet::Provider::Keystone
) do

  desc <<-EOT
    Provider that uses the keystone client tool to
    manage keystone role assignments to users
  EOT

  optional_commands :keystone => "keystone"


  def self.prefetch(resource)
    # rebuild the cahce for every puppet run
    @user_role_hash = nil
  end

  def self.user_role_hash
    @user_role_hash ||= build_user_role_hash
  end

  def user_role_hash
    self.class.user_role_hash
  end

  def self.instances
    user_role_hash.collect do |k, v|
      new(:name => k)
    end
  end

  def create
    user_id, tenant_id = get_user_and_tenant
    resource[:roles].each do |role_name|
      role_id = self.class.get_role(role_name)
      auth_keystone(
        'user-role-add',
        '--user-id', user_id,
        '--tenant-id', tenant_id,
        '--role-id', role_id
      )
    end
  end

  def self.get_user_and_tenant(user, tenant)
    @tenant_hash ||= {}
    @user_hash   ||= {}
    @tenant_hash[tenant] = @tenant_hash[tenant] || get_tenant(tenant)
    [
      get_user(@tenant_hash[tenant], user),
      @tenant_hash[tenant]
    ]
  end

  def get_user_and_tenant
    user, tenant = resource[:name].split('@', 2)
    self.class.get_user_and_tenant(user, tenant)
  end

  def exists?
    user_id, tenant_id = get_user_and_tenant
    get_user_tenant_hash(user_id, tenant_id)
  end

  def destroy
    user_id, tenant_id = get_user_and_tenant
    get_user_tenant_hash(user_id, tenant_id)[:role_ids].each do |role_id|
      auth_keystone(
       'user-role-remove',
       '--user-id', user_id,
       '--tenant-id', tenant_id,
       '--role-id', role_id
      )
    end
  end

  def id
    user_id, tenant_id = get_user_and_tenant
    get_user_tenant_hash(user_id, tenant_id)[:id]
  end

  def roles
    user_id, tenant_id = get_user_and_tenant
    get_user_tenant_hash(user_id, tenant_id)[:role_names]
  end

  def roles=(value)
    # determine the roles to be added and removed
    remove = roles - Array(value)
    add    = Array(value) - roles

    user_id, tenant_id = get_user_and_tenant

    add.each do |role_name|
      role_id = self.class.get_role(role_name)
      auth_keystone(
        'user-role-add',
        '--user-id', user_id,
        '--tenant-id', tenant_id,
        '--role-id', role_id
      )
    end
    remove.each do |role_name|
      role_id = self.class.get_role(role_name)
      auth_keystone(
        'user-role-remove',
        '--user-id', user_id,
        '--tenant-id', tenant_id,
        '--role-id', role_id
      )
    end

  end

  private

    def self.build_user_role_hash
      hash = {}
      get_tenants.each do |tenant_name, tenant_id|
        get_users(tenant_id).each do |user_name, user_id|
          list_user_roles(user_id, tenant_id).sort.each do |role|
            hash["#{user_name}@#{tenant_name}"] ||= {
              :user_id    => user_id,
              :tenant_id  => tenant_id,
              :role_names => [],
              :role_ids   => []
            }
            hash["#{user_name}@#{tenant_name}"][:role_names].push(role[1])
            hash["#{user_name}@#{tenant_name}"][:role_ids].push(role[0])
          end
        end
      end
      hash
    end

    # lookup the roles for a single tenant/user combination
    def get_user_tenant_hash(user_id, tenant_id)
      @user_tenant_hash ||= {}
      unless @user_tenant_hash["#{user_id}@#{tenant_id}"]
        list_user_roles(user_id, tenant_id).sort.each do |role|
          @user_tenant_hash["#{user_id}@#{tenant_id}"] ||= {
            :user_id    => user_id,
            :tenant_id  => tenant_id,
            :role_names => [],
            :role_ids   => []
          }
          @user_tenant_hash["#{user_id}@#{tenant_id}"][:role_names].push(role[1])
          @user_tenant_hash["#{user_id}@#{tenant_id}"][:role_ids].push(role[0])
        end
      end
      @user_tenant_hash["#{user_id}@#{tenant_id}"]
    end


    def self.list_user_roles(user_id, tenant_id)
      # this assumes that all returned objects are of the form
      # id, name, enabled_state, OTHER
      number_columns = 4
      role_output = auth_keystone('user-role-list', '--user-id', user_id, '--tenant-id', tenant_id)
      list = (role_output.split("\n")[3..-2] || []).collect do |line|
        row = line.split(/\s*\|\s*/)[1..-1]
        if row.size != number_columns
          raise(Puppet::Error, "Expected #{number_columns} columns for #{type} row, found #{row.size}. Line #{line}")
        end
        row
      end
      list
    end

    def list_user_roles(user_id, tenant_id)
      self.class.list_user_roles(user_id, tenant_id)
    end

    def self.get_user(tenant_id, name)
      @users ||= {}
      user_key = "#{name}@#{tenant_id}"
      unless @users[user_key]
        list_keystone_objects('user', 4, '--tenant-id', tenant_id).each do |user|
          @users["#{user[1]}@#{tenant_id}"] = user[0]
        end
      end
      @users[user_key]
    end

    def self.get_users(tenant_id='')
      @users = {}
      list_keystone_objects('user', 4, '--tenant-id', tenant_id).each do |user|
        @users[user[1]] = user[0]
      end
      @users
    end

    def self.get_tenants
      unless @tenants
        @tenants = {}
        list_keystone_objects('tenant', 3).each do |tenant|
          @tenants[tenant[1]] = tenant[0]
        end
      end
      @tenants
    end

    def self.get_tenant(name)
      unless (@tenants and @tenants[name])
        @tenants = {}
        list_keystone_objects('tenant', 3).each do |tenant|
          if tenant[1] == name
            @tenants[tenant[1]] = tenant[0]
            #tenant
          end
        end
      end
      @tenants[name]
    end

    def self.get_role(name)
      @roles ||= {}
      unless @roles[name]
        list_keystone_objects('role', 2).each do |role|
          @roles[role[1]] = role[0]
        end
      end
      @roles[name]
    end

end
