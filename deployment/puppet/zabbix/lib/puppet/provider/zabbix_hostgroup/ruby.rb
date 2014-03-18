$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', '..'))
require 'puppet/provider/zabbix'

Puppet::Type.type(:zabbix_hostgroup).provide(:ruby,
                                             :parent => Puppet::Provider::Zabbix) do

  def exists?
    auth(resource[:api])
    result = get_hostgroup(resource[:api], resource[:name])
    not result.empty?
  end

  def create
    api_request(resource[:api],
                {:method => "hostgroup.create",
                 :params => {:name => resource[:name]}})
  end

  def destroy
    groupid = get_hostgroup(resource[:api], resource[:name])[0]["groupid"]
    api_request(resource[:api],
                {:method => "hostgroup.delete",
                 :params => [groupid]})
  end
end
