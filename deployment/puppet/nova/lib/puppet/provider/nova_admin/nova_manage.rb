Puppet::Type.type(:nova_admin).provide(:nova_manage) do

  desc "Manage nova admin user"

  optional_commands :nova_manage => 'nova-manage'

  def exists?
    nova_manage("user", "list").match(/^#{resource[:name]}$/)
  end

  def create
    nova_manage("user", "admin", resource[:name])
  end

  def destroy
    nova_manage("user", "delete", resource[:name])
  end

end

