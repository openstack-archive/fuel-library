Puppet::Type.type(:nova_project).provide(:nova_manage) do

  desc "Manage nova project"

  defaultfor :kernel => 'Linux'

  commands :nova_manage => 'nova-manage'

  def exists?
    nova_manage("project", "list").match(/^#{resource[:name]}$/)
  end

  def create
    nova_manage("project", "create", resource[:name], resource[:owner])
  end

  def destroy
    nova_manage("project", "delete", resource[:name])
  end

end
