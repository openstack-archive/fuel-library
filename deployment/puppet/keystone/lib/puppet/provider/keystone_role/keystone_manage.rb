require 'puppet/provider/keystone_manage'
Puppet::Type.type(:keystone_role).provide(
  :keystone_manage,
  :parent => Puppet::Provider::KeystoneManager
) do

  optional_commands :keystone_manage => 'keystone-manage'

  def self.instances
    role_hash.collect do |k, v|
      puts "|#{k}|"
      new(:name => k)
    end
  end

  def create
    keystone_manage('role', 'add', resource[:name], resource[:service])
  end

  def exists?
    role_hash[resource[:name]]
  end

  def destroy
    raise(Puppet::Error, "keystone-manage does not support removing roles")
  end

  def id
    role_hash[resource[:name]][:id]
  end

  def service
    role_hash[resource[:name]][:service]
  end

  def description
    role_hash[resource[:name]][:description]
  end

  def id=(id)
    raise(Puppet::Error, "Id is a read only property")
  end

  def service=(service_name)
    property_not_supported('service')
  end

  def description=(description)
    property_not_supported('description')
  end

end
