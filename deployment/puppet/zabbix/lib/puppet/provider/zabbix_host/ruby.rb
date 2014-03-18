$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', '..'))
require 'puppet/provider/zabbix'

Puppet::Type.type(:zabbix_host).provide(:ruby,
                                        :parent => Puppet::Provider::Zabbix) do

  def exists?
    auth(resource[:api])
    result = get_host(resource[:api], resource[:name])
    not result.empty?
  end

  def create
    groups = Array.new
    resource[:groups].each do |group|
      group_id = get_hostgroup(resource[:api], group)
      raise(Puppet::Error, "Group #{group} does not exist") unless not group_id.empty?
      groups.push({
        :groupid => group_id[0]["groupid"]
      })
    end

    params = {:host => resource[:host],
              :status => resource[:status],
              :interfaces => [{:type => 1,
                               :main =>1,
                               :useip => resource[:ip] == nil ? 0 : 1,
                               :usedns => resource[:ip] == nil ? 1 : 0,
                               :dns => resource[:host],
                               :ip => resource[:ip] == nil ? "" : resource[:ip],
                               :port => 10050,}],
              :proxy_hostid => resource[:proxy_hostid] == nil ? 0 : resource[:proxy_hostid],
              :groups => groups}

    api_request(resource[:api],
                {:method => "host.create",
                 :params => params})
  end

  def destroy
    hostid = get_host(resource[:api], resource[:name])[0]["hostid"]
    # deactivate before removing
    api_request(resource[:api],
                {:method => 'host.update',
                 :params => {:hostid => hostid,
                             :status => 1}})

    api_request(resource[:api],
                {:method => 'host.delete',
                 :params => [{:hostid => hostid}]})
  end
end
