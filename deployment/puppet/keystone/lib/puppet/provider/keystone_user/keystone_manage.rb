require 'puppet/provider/keystone_manage'
Puppet::Type.type(:keystone_user).provide(
  :keystone_manage,
  :parent => Puppet::Provider::KeystoneManager
) do

  optional_commands :keystone_manage => 'keystone-manage'

  def self.instances
    user_hash.collect do |k, v|
      puts "|#{k}|"
      new(:name => k)
    end
  end

  def create
    ['tenant', 'password'].each do |x|
      raise(Puppet::Error, "Cannot create keystone user without parameter: #{x}") unless self[x.to_sym]
    end
    keystone_manage(
      'user',
      'add',
      resource[:name],
      resource[:password],
      resource[:tenant]
    )
  end

  def exists?
    user_hash[resource[:name]] and user_hash[resource[:name]][:enabled] == 'True'
  end

  def destroy
    Puppet.warning("Deleting the user is not currently supported, it will be disabled")
    keystone_manage('user', 'disable', resource[:name])
  end

  def tenant=(tenant)
    raise(Puppet::Error, "Setting the user tenant property is currently not supported")
  end

  def tenant
    # I need to translate this from the other command
    tenant_id = user_hash[resource[:name]][:tenant]
    if tenant_id == 'None'
      'None'
    else
      # maybe I should check more explicityly
      # to see if the id is valid
      tenant_hash.find {|k,v| v[:id] == tenant_id  }[0]
    end
  end

end
