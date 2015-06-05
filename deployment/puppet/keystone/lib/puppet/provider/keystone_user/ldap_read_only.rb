require File.join File.dirname(__FILE__), '../keystone.rb'

Puppet::Type.type(:keystone_user).provide(
    :ldap_read_only,
    :parent => Puppet::Provider::Keystone
) do

  desc <<-EOT
    Provider that uses the keystone client tool to
    manage keystone users

    Doesn't do any changes.
  EOT

  command :keystone => 'keystone'

  def self.prefetch(resource)
    # rebuild the cahce for every puppet run
    @user_hash = nil
  end

  def self.user_hash
    @user_hash = build_user_hash
  end

  def user_hash
    self.class.user_hash
  end

  def self.instances
    user_hash.collect do |k, v|
      new(:name => k)
    end
  end

  def create
    warn "Create this user in your LDAP manually!"
  end

  def exists?
    user_hash[resource[:name]]
  end

  def destroy
    warn "Remove this user in your LDAP manually!"
  end

  def enabled
    user_hash[resource[:name]][:enabled]
  end

  def enabled=(value)
    warn "Enable or disable this user in your LDAP manually!"
  end

  def password
    nil
  end

  def password=(value)
    warn "Set password for this user in your LDAP manually!"
  end

  def tenant
    return resource[:tenant] if resource[:ignore_default_tenant]
    user_id = user_hash[resource[:name]][:id]
    begin
      tenant_id = self.class.get_keystone_object('user', user_id, 'tenantId')
    rescue
      tenant_id = nil
    end
    if tenant_id.nil? or tenant_id == 'None' or tenant_id.empty?
      tenant = 'None'
    else
      # this prevents is from failing if tenant no longer exists
      begin
        tenant = self.class.get_keystone_object('tenant', tenant_id, 'name')
      rescue
        tenant = 'None'
      end
    end
    tenant
  end

  def tenant=(value)
    warn "Tenant cannot be updated!"
  end

  def email
    user_hash[resource[:name]][:email]
  end

  def email=(value)
    warn "Set email for this user in your LDAP manually!"
  end

  def manage_password
    false
  end

  def manage_password=(value)
    warn "Set password for this user in your LDAP manually!"
  end

  def id
    user_hash[resource[:name]][:id]
  end

  private

  def self.build_user_hash
    hash = {}
    list_keystone_objects('user', 4).each do |user|
      hash[user[1]] = {
          :id              => user[0],
          :name            => user[1],
          :enabled         => user[2],
          :email           => user[3],
      }
    end
    hash
  end

end

