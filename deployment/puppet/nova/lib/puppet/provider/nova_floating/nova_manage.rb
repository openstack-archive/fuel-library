Puppet::Type.type(:nova_floating).provide(:nova_manage) do

  desc "Manage nova floating"

  optional_commands :nova_manage => 'nova-manage'

  def exists?
    begin
      # TODO this assumes that the CIDR is 24
      # this may be good for an approximation, but it needs to be fixed eventually
      prefix=resource[:network].sub(/(^[0-9]*\.[0-9]*\.[0-9]*\.).*/, '\1')
      return nova_manage("floating", "list").match(/#{prefix}/)
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
