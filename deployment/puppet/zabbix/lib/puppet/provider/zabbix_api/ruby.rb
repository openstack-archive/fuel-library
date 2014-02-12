# == Type: zabbix_api
#
#
Puppet::Type.type(:zabbix_api).provide(:ruby) do
  confine :feature => :zabbixapi

  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../../../../lib/ruby/")
  require "zabbix"

  def exists?
    case resource[:type]
    when "template"
      template_exists?(resource[:name])
    when "item"
      item_exists?(resource[:name], resource[:host])
    when "application"
      application_exists?(resource[:name], resource[:host])
    when "trigger"
      trigger_exists?(
        resource[:name], 
        resource[:host], 
        resource[:description]
      )
    else
      raise Puppet::Error, "zabbix_api: non existant type '#{resource[:type]}'"
    end
  end

  def create
    case resource[:type]
    when "template"
      template_create(resource[:name], resource[:hostgroup])
    when "item"
      item_create(resource[:name], resource[:host], resource[:description], resource[:application])
    when "application"
      application_create(resource[:name], resource[:host])
    when "trigger"
      trigger_create(
        resource[:name], 
        resource[:host], 
        resource[:description], 
        resource[:trigger_type], 
        resource[:trigger_status]
      )
    end
  end

  def destroy
    case resource[:type]
    when "template"
      template_destroy(resource[:name])
    when "item"
      item_destroy(resource[:name], resource[:host])
    when "application"
      application_destroy(resource[:name], resource[:host])
    when "trigger"
      trigger_destroy(resource[:name], resource[:host], resource[:description])
    end
  end
  
  private
  @server
  
  def load_server
    # Load the zbxapi based interface
    if !@server 
      @server = ZabbixAPI.new(resource[:server])
      if resource[:proxy_host] != nil 
        @server.set_proxy(resource[:proxy_host] ,resource[:proxy_password])
      end
      @server.login(resource[:user],resource[:password])
    end
  end
  
  def template_exists?(name)
    # Check if a template exists on the server
    load_server()
    return @server.template.exists({"host" => name})
  end
  
  def template_create(name, hostgroup)
    load_server()
    hostgroup_templates = @server.hostgroup.get({
      "filter" => {
        "name" => hostgroup
      }
    })
    @server.template.create({
      "host"   => name, 
      "groups" => hostgroup_templates
    })
  end
  
  def template_destroy(name)
    load_server()
    templates = @server.template.get({
      "filter" => {
        "host" => name
      }
    })
    templates.collect! {|t| t = t.fetch('templateid')}
    @server.template.delete(templates)
  end
  
  def application_exists?(name, host)
    load_server()
    return @server.application.exists({"name" => name, "host" => host})
  end
  
  def application_create(name, host)
    load_server()
    @server.application.create({
      "name"         => name
    }.merge(Hash[*host_get_hostids(host)]))
    
    if not application_exists?(name, host)
      raise Puppet::Error, "create failed '%s'" % name
    end
  end
  
  def application_destroy(name, host)
    load_server()
    
    applications = @server.application.get({
      "filter" => {
        "name" => name,
      }, "output" => "extend"
    })
    applications.collect! {|a| a = a.fetch('applicationid')}
    @server.application.delete(applications)
    if application_exists?(name, host)
      raise Puppet::Error, "destroy failed '%s'" % name
    end
  end
  
  def item_exists?(name, host)
    load_server()
    return @server.item.exists({"key_" => name, "host" => host})
  end
  
  def item_create(name, host, description, application = '')
    load_server()
    unless host_exists?(host) or template_exists?(host)
      raise Puppet::Error, "missing host '#{resource[:host]}'"
    end
    unless application != '' and application_exists?(application, host)
      raise Puppet::Error, "missing application '#{resource[:application]}'"
    end
    
    applications = @server.application.get({
      "filter" => {
        "name" => application
      }
    })
    applications.collect! {|a| a = a.fetch("applicationid")}
    
    new = {
      "key_"         => name,
      "name"         => description,
      "applications" => applications,
      "interfaceid"  => 0,
      "status"       => '0',
      "delay"        => 60,
      "type"         => 0,
      "value_type"   => 0
    }.merge(Hash[*host_get_hostids(host)])
    
    @server.item.create(new)
    if not item_exists?(name, host)
      raise Puppet::Error, "create failed '%s'" % name
    end
  end
  
  def item_destroy(name, host)
    load_server()
    items = @server.item.get({
      "filter" => {
        "key_" => name,
        "host" => host
      }, "output" => "extend"
    })
    items.collect! {|i| i = i.fetch('itemid')}
    @server.item.delete(Array[*items])
  end
  
  
  def trigger_exists?(name, host, description)
    load_server()
    return @server.trigger.exists({
      "expression"  => name, 
      "description" => description,
      "host"        => host
    })
  end
  
  def trigger_create(name, host, description, type, status)
    load_server()
    
    new = {
      "expression"  => name, 
      "description" => description,
      "type"        => type,
      "status"      => status
    }.merge(host_get_hostids(host, false, true))
    
    @server.trigger.create(new)
    
    if not trigger_exists?(name, host, description)
      raise Puppet::Error, "create failed"
    end
  end
  
  def trigger_destroy(name, host, description)
    load_server()
    triggers = @server.trigger.get({
      "filter" => {
        "description" => [description],
        "hostids"     => [host_get_hostids(host)]
      }
    })
    triggers.collect! {|i| i = i.fetch('triggerid')}
    @server.trigger.delete(triggers)
  end
  
  def host_exists?(name)
    load_server()
    return @server.host.exists({"host" => name})
  end
  
  def host_get_hostids(name, template_as_is = false, first = false)
    if host_exists?(name) 
      host_array = @server.host.get({
        "filter" => {
          "host" => name
        }
      })
    elsif template_exists?(name) 
      host_array = @server.template.get({
        "filter" => {
          "host" => name
        }
      })
      if !template_as_is
        host_array.collect! {|t| t = {"hostid" => t.fetch("templateid") } }
      end
    end
    if first
      host_array = host_array.first
    end
    return host_array

  end

end
