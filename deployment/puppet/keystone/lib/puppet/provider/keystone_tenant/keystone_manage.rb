require 'puppet/provider/keystone_manage'
Puppet::Type.type(:keystone_tenant).provide(
  :keystone_manage,
  :parent => Puppet::Provider::KeystoneManager
) do

  desc <<-EOT

    Provider that uses the keystone-manage tool to
    manage keystone tenants

    As of the essex release, there is no way to delete an existing
    tenant. A disabled tenant will be considered the same as an
    absent tenant (although they are not quite the same, I do not
    think it will be possible to create a tenant once it has been
    deleted)

  EOT

  optional_commands :keystone_manage => 'keystone-manage'

  def self.instances
    tenant_hash.collect do |k, v|
      new(:name => k)
    end
  end

  def create
    keystone_manage('tenant', 'add', resource[:name])
  end

  def exists?
    # a tenant is absent if it doesnt exist or if it is disabled
    tenant_hash[resource[:name]] and tenant_hash[resource[:name]][:enabled] == 'True'
  end

  def destroy
    Puppet.warning("Deleting the tenant is not currently supported, it will be disabled")
    keystone_manage('tenant', 'disable', resource[:name])
  end

#  def enabled=(state)
#    if state == 'True'
#      raise(Puppet::Error, 'Enabling a disabled Tenant is not currently supported')
#    else
#      keystone_manage('tenant', 'disable', resource[:name])
#    end
#  end

#  def enabled
#    tenant_hash[resource['name']][:enabled]
#  end

  def id
    tenant_hash[resource['name']][:id]
  end
end
