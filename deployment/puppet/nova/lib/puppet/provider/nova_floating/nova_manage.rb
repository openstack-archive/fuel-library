Puppet::Type.type(:nova_floating).provide(:nova_manage) do

  desc "Manage nova floating"

  optional_commands :nova_manage => 'nova-manage'

  def exists?
    begin
      # Calculate num quads to grab for prefix
      mask=resource[:network].sub(/.*\/([1-3][0-9]?)/) 
      case 
        when mask <= 8
          num_quads=1
        when mask <=16
          num_quads=2
        when mask <=24
          num_quads=3
        when mask <=32
          num_quads=3
      end
      prefix=resource[:network].sub(/(\.[0-9]{1,3}){#{num_quads}}(\/[0-9]{1,2})?$/, '') + "."
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
