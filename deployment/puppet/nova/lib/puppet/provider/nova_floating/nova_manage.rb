Puppet::Type.type(:nova_floating).provide(:nova_manage) do

  desc "Manage nova floating"

  optional_commands :nova_manage => 'nova-manage'

  def exists?
    # Calculate num quads to grab for prefix
    mask=resource[:network].sub(/.*\/([0-9][0-9]?)/, '\1').to_i
    num_quads = 4 - mask / 8
    prefix=resource[:network].sub(/(\.[0-9]{1,3}){#{num_quads}}(\/[0-9]{1,2})?$/, '') + "."
    return nova_manage("floating", "list").match(/#{prefix}/)
  end

  def create
     nova_manage("floating", "create", '--pool', resource[:pool], resource[:network])
  end

  def destroy
    nova_manage("floating", "delete", resource[:network])
  end

end
