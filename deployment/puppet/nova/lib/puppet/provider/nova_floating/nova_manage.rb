Puppet::Type.type(:nova_floating).provide(:nova_manage) do

  desc "Manage nova floating"

  optional_commands :nova_manage => 'nova-manage'

  @@cache_floating_list = nil
  def exists?
    if resource[:network].match(/\//)
      # Calculate num quads to grab for prefix
      mask=resource[:network].sub(/.*\/([0-9][0-9]?)/, '\1').to_i
      num_quads = 4 - mask / 8
      prefix=Regexp.escape(resource[:network].sub(/(\.[0-9]{1,3}){#{num_quads}}(\/[0-9]{1,2})?$/, '') + ".")
    else
      prefix = Regexp.new('[[:space:]]' + resource[:network] + '[[:space:]]')
    end
    @@cache_floating_list ||= nova_manage("floating", "list")
    return @@cache_floating_list.match(prefix)
  end

  def create
    nova_manage("floating", "create", resource[:network])
    if resource[:network].match(/\//)
      @@cache_floating_list = nil
    else
      @@cache_floating_list += " #{resource} "
    end
  end

  def destroy
    nova_manage("floating", "delete", resource[:network])
    @@cache_floating_list = nil
  end

  def parse
    /([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})(\/([0-9]{1,2}))?/ =~ resource[:network]
    [Regexp.last_match(1), Regexp.last_match(3)]
  end

end
