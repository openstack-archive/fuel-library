$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', '..'))
require 'puppet/provider/keystone'
Puppet::Type.type(:keystone_user).provide(
  :keystone,
  :parent => Puppet::Provider::Keystone
) do

  desc <<-EOT
    Provider that uses the keystone client tool to
    manage keystone users

    This provider makes a few assumptions/
      1. assumes that the admin endpoint can be accessed via localhost.
      2. Assumes that the admin token and port can be accessed from
         /etc/keystone/keystone.conf

    Does not support the ability to update the user's name
  EOT

  optional_commands :keystone => "keystone"

  def self.prefetch(resource)
    # rebuild the cahce for every puppet run
    @user_hash = nil
  end

  def self.user_hash
    @user_hash ||= build_user_hash
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
    optional_opts = []
    if resource[:email]
      optional_opts.push('--email').push(resource[:email])
    end
    if resource[:password]
      optional_opts.push('--pass').push(resource[:password])
    end
    if resource[:tenant]
      tenant_id = self.class.list_keystone_objects('tenant', 3).collect {|x|
        x[0] if x[1] == resource[:tenant]
      }.compact[0]
      optional_opts.push('--tenant_id').push(tenant_id)
    end
    auth_keystone(
      'user-create',
      '--name', resource[:name],
      '--enabled', resource[:enabled],
      optional_opts
    )
  end

  def exists?
    user_hash[resource[:name]]
  end

  def destroy
    auth_keystone('user-delete', user_hash[resource[:name]][:id])
  end

  def enabled
    user_hash[resource[:name]][:enabled]
  end

  def enabled=(value)
    auth_keystone(
      "user-update",
      '--enabled', value,
      user_hash[resource[:name]][:id]
    )
  end

#  def password
#    Puppet.warning("Cannot retrieve password")
#    user_hash[resource[:name]][:password]
#  end
#
#  def password=(value)
#    Puppet.warning('Cannot update password')
#    # user-password-update does not support the ability know what the
#    # current value is
#    #auth_keystone(
#    #  'user-password-update',
#    #  '--pass', value,
#    #  user_hash[resource[:name]][:id]
#  end

  def tenant
    user_hash[resource[:name]][:tenant]
  end

  def tenant=(value)
    fail("tenant cannot be updated. Transition requested: #{user_hash[resource[:name]][:tenant]} -> #{value}")
  end

  def email
    user_hash[resource[:name]][:email]
  end

  def email=(value)
    auth_keystone(
      "user-update",
      '--email', value,
      user_hash[resource[:name]][:id]
    )
  end

  def id
    user_hash[resource[:name]][:id]
  end

  private

    def self.build_user_hash
      hash = {}
      list_keystone_objects('user', 4).each do |user|
        tenantId = get_keystone_object('user', user[0], 'tenantId')
        if tenantId.nil? or tenantId == 'None' or tenantId.empty?
          tenant = 'None'
        else
          tenant = get_keystone_object('tenant', tenantId, 'name')
        end
        password = 'nil'
        hash[user[1]] = {
          :id          => user[0],
          :enabled     => user[2],
          :email       => user[3],
          :name        => user[1],
          :password    => password,
          :tenant      => tenant
        }
      end
      hash
    end

end
