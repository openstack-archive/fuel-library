require "puppet"

Puppet::Type.type(:vs_bridge).provide(:ovs) do
  commands :vsctl => "/usr/bin/ovs-vsctl"

  def exists?
    vsctl("br-exists", @resource[:name])
  rescue Puppet::ExecutionFailure
    return false
  end

  def create
    vsctl("add-br", @resource[:name])
    external_ids = @resource[:external_ids] if@resource[:external_ids]
  end

  def destroy
    vsctl("del-br", @resource[:name])
  end

  def _split(string, splitter=",")
    return Hash[string.split(splitter).map{|i| i.split("=")}]
  end

  def external_ids
    result = vsctl("br-get-external-id", @resource[:name])
    return result.split("\n").join(",")
  end

  def external_ids=(value)
    old_ids = _split(external_ids)
    new_ids = _split(value)

    new_ids.each_pair do |k,v|
      unless old_ids.has_key?(k)
        vsctl("br-set-external-id", @resource[:name], k, v)
      end
    end
  end
end
