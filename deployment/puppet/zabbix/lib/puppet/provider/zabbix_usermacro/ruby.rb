$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', '..'))
require 'puppet/provider/zabbix'

Puppet::Type.type(:zabbix_usermacro).provide(:ruby,
                                        :parent => Puppet::Provider::Zabbix) do

  def exists?
    auth(resource[:api])
    macroid = nil
    if resource[:global] == :true
      result = api_request(resource[:api],
                           {:method => "usermacro.get",
                            :params => {:globalmacro => true,
                                        :output     => "extend"}})
      result.each { |macro| macroid = macro["globalmacroid"] if macro['macro'] == resource[:macro] }
    else
      hostid = get_host(resource[:api], resource[:host])
      raise(Puppet::Error, "Host #{resource[:host]} does not exist") unless not hostid.empty?
      result = api_request(resource[:api],
                           {:method => 'usermacro.get',
                            :params => {"hostids" => hostid[0]["hostid"],
                            :output => "extend"}})
      macroid = nil
      result.each { |macro| macroid = macro['hostmacroid'] if macro['macro'] == resource[:macro] }
    end
    not macroid.nil?
  end

  def create
    if resource[:global] == :true
      api_request(resource[:api],
                  {:method => 'usermacro.createglobal',
                   :params => {:macro  => resource[:macro],
                               :value  => resource[:value]}})
    else
      hostid = get_host(resource[:api], resource[:host])
      api_request(resource[:api],
                  {:method => 'usermacro.create',
                   :params => {:macro => resource[:macro],
                               :value => resource[:value],
                               :hostid => hostid[0]["hostid"]}})
    end
  end

  def destroy
    macroid = nil
    if resource[:global] == :true
      result = api_request(resource[:api],
                           {:method => 'usermacro.get',
                            :params => {:globalmacro => true,
                                        :output      => "extend"}})
      result.each { |macro| macroid = macro['globalmacroid'] if macro['macro'] == resource[:macro] }
      api_request(resource[:api],
                  {:method => 'usermacro.deleteglobal',
                   :params => [macroid]})
    else
      hostid = get_host(resource[:api], resource[:host])
      result = api_request(resource[:api],
                           {:method => 'usermacro.get',
                            :params => {:hostids => hostid[0]["hostid"],
                                       :output  => "extend"}})
      result.each { |macro| macroid = macro['hostmacroid'] if macro['macro'] == resource[:macro] }
      api_request(resource[:api],
                  {:method => 'usermacro.delete',
                   :params => [macroid]})
    end
  end

  def value
    #get value
    macrovalue = nil
    if resource[:global] == :true
      result = api_request(resource[:api],
                           {:method => 'usermacro.get',
                            :params => {:globalmacro => true,
                                        :output => "extend"}})
      result.each { |macro| macrovalue = macro['value'] if macro['macro'] == resource[:macro] }
    else
      hostid = get_host(resource[:api], resource[:host])
      result = api_request(resource[:api],
                           {:method => 'usermacro.get',
                            :params => {:hostids => hostid[0]["hostid"],
                                        :output  => "extend"}})
      result.each { |macro| macrovalue = macro['value'] if macro['macro'] == resource[:macro] }
    end
    macrovalue
  end

  def value=(v)
    #set value
    macroid = nil
    if resource[:global] == :true
      result = api_request(resource[:api],
                           {:method => 'usermacro.get',
                            :params => {:globalmacro => true,
                                        :output      => "extend"}})
      result.each { |macro| macroid = macro['globalmacroid'].to_i if macro['macro'] == resource[:macro] }
      api_request(resource[:api],
                  {:method => 'usermacro.updateglobal',
                   :params => {:globalmacroid => macroid,
                               :value         => resource[:value]}})
    else
      hostid = get_host(resource[:api], resource[:host])
      result = api_request(resource[:api],
                           {:method => 'usermacro.get',
                            :params => {:hostids => hostid[0]["hostid"],
                                        :output  => "extend"}})
      result.each { |macro| macroid = macro['hostmacroid'].to_i if macro['macro'] == resource[:macro] }
      api_request(resource[:api],
                  {:method => 'usermacro.update',
                   :params => {:hostmacroid => macroid,
                               :value       => resource[:value]}})
    end
  end

end
