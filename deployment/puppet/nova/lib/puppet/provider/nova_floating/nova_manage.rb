Puppet::Type.type(:nova_floating).provide(:nova_manage) do

  desc "Manage nova floating"

  defaultfor :kernel => 'Linux'

  commands :nova_manage => 'nova-manage'

  def exists?
    begin
      prefix=resource[:network].sub(/(^[0-9]*\.[0-9]*\.[0-9]*\.).*/, '\1')
      return false if not nova_manage("floating", "list").match(/#{prefix}/)
    rescue
      return false
    end
  end

  def create
     nova_manage("floating", "create", resource[:network]) if exists? == false
  end

  def destroy
    nova_manage("floating", "delete", resource[:network])
  end

end
