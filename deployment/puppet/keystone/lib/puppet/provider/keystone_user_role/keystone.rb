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
      role_id = self.class.get_roles[role_name]
      auth_keystone(
        'user-role-add',
        '--user-id', user_id,
        '--tenant-id', tenant_id,
        '--role-id', role_id
      )
    end
  end

  def get_user_and_tenant
    user, tenant = resource[:name].split('@', 2)
    tenant_id = self.class.get_tenants[tenant]
    [self.class.get_users(tenant_id)[user], self.class.get_tenants[tenant]]
  end

  def exists?
    user_role_hash[resource[:name]]
  end

  def destroy
    user_role_hash[resource[:name]][:role_ids].each do |role_id|
      begin
        auth_keystone(
          'user-role-remove',
          '--user-id', user_role_hash[resource[:name]][:user_id],
          '--tenant-id', user_role_hash[resource[:name]][:tenant_id],
          '--role-id', role_id
        )
      rescue Exception => e
        if e.message =~ /(\(HTTP\s+404\))/
          notice("Role has been already deleted. Nothing to do")
        else
          raise(e)
        end
      end
    end
  end

  def id
    user_role_hash[resource[:name]][:id]
  end

  def roles
    user_role_hash[resource[:name]][:role_names]
  end

  def roles=(value)
    # determine the roles to be added and removed
    # require 'ruby-debug';debugger
    remove = roles - Array(value)
    add    = Array(value) - roles

    user_id, tenant_id = get_user_and_tenant

    add.each do |role_name|
      role_id = self.class.get_roles[role_name]
      auth_keystone(
        'user-role-add',
        '--user-id', user_id,
        '--tenant-id', tenant_id,
        '--role-id', role_id
      )
    end
    remove.each do |role_name|
      role_id = self.class.get_roles[role_name]
      begin
          auth_keystone(
              'user-role-remove',
              '--user-id', user_id,
              '--tenant-id', tenant_id,
              '--role-id', role_id
          )
      rescue Exception => e
        if e.message =~ /(\(HTTP\s+404\))/
            notice("Role has been already deleted. Nothing to do")
        else
          raise(e)
        end
      end
    end
  end

  private

    def self.build_user_role_hash
      hash = {}
      get_tenants.each do |tenant_name, tenant_id|
        get_users(tenant_id).each do |user_name, user_id|
          list_user_roles(user_id, tenant_id).each do |role|
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
#require 'ruby-debug';debugger
      hash
    end


    def self.list_user_roles(user_id, tenant_id)
      # this assumes that all returned objects are of the form
      # id, name, enabled_state, OTHER
      number_columns = 4
      role_output = auth_keystone('user-role-list', '--user-id', user_id, '--tenant-id', tenant_id)
      list = (role_output.split("\n")[3..-2] || []).select do 
          |line| line =~ /^\|.*\|$/
      end.reject do
              |line| line =~ /^\|\s+id\s+\|\s+name\s+\|\s+user_id\s+\|\s+tenant_id\s+\|$/
      end.collect do |line|
        row = line.split(/\s*\|\s*/)[1..-1]
        if row.size != number_columns
          raise(Puppet::Error, "Expected #{number_columns} columns for #{type} row, found #{row.size}. Line #{line}")
        end
        row
      end
      list
    end

    def self.get_users(tenant_id='')
      @users = {}

      list_keystone_objects('user', 4, '--tenant-id', tenant_id).each do |user|
        @users[user[1]] = user[0]
      end
      @users
    end

    def self.get_tenants
      @tenants = {}
      list_keystone_objects('tenant', 3).each do |tenant|
        @tenants[tenant[1]] = tenant[0]
      end
      @tenants
    end

    def self.get_roles
      @roles = {}
      list_keystone_objects('role', 2).each do |role|
        @roles[role[1]] = role[0]
      end
      @roles
    end

end
