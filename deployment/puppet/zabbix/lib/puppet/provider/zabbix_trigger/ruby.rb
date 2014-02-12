
Puppet::Type.type(:zabbix_trigger).provide(:ruby) do
  desc "zabbix trigger provider"
  confine :feature => :zabbixapi

  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../../../../lib/ruby/")
  require "zabbix"
  require 'pp'

  def exists?
    by_expression(
      :expression => resource[:expression]
    )  != nil
  end
  
  def create
    extend Zabbix
    zbx.triggers.create(
      :description => resource[:description],
      :expression => resource[:expression],
      :comments => resource[:comments],
      :priority => resource[:priority],
      :status => resource[:status],
      :type => resource[:type],
      :url => resource[:url]
    )
  end
  
  def destroy
    extend Zabbix
    trigger = by_expression(
      :expression => resource[:expression]
    )
    zbx.triggers.delete(
      trigger["triggerid"]
    )
  end

  def by_expression(data)
    extend Zabbix
    result = zbx.client.api_request(
      :method => "trigger.get",
      :params => {
        :filter => data,
        :output => "extend",
        :expandExpression => "data"
      })
    trigger = nil
    result.each { |template| trigger = template if template["expression"] == data[:expression] }
    trigger
  end
end
