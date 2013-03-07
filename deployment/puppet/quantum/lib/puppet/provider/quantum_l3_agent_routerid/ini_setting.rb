require 'puppet/util/inifile'
require 'tempfile'  

Puppet::Type.type(:ini_setting)#.providers

Puppet::Type.type(:quantum_l3_agent_routerid).provide(
  :ini_setting,
  :parent => Puppet::Type.type(:ini_setting).provider(:ruby)
) do

    optional_commands :quantum => "quantum"

  def self.quantum_credentials
    @quantum_credentials ||= get_quantum_credentials
  end

  def self.get_quantum_credentials
    if quantum_file and quantum_file['DEFAULT'] and 
      quantum_file['DEFAULT']['auth_url'] and
      quantum_file['DEFAULT']['admin_tenant_name'] and
      quantum_file['DEFAULT']['admin_user'] and
      quantum_file['DEFAULT']['admin_password']


        q = {}
        q['auth_url'] = quantum_file['DEFAULT']['auth_url'].strip
        q['admin_tenant_name'] = quantum_file['DEFAULT']['admin_tenant_name'].strip
        q['admin_user'] = quantum_file['DEFAULT']['admin_user'].strip
        q['admin_password'] = quantum_file['DEFAULT']['admin_password'].strip
        return q
    else
      # raise(Puppet::Error, 'File: /etc/quantum/api-paste.ini does not contain all required sections.')
      # raise(Puppet::Error, 'File: /etc/quantum/l3_agent.ini does not contain all required sections.')
    end
  end

  def quantum_credentials
    self.class.quantum_credentials
  end

  def self.auth_endpoint
    @auth_endpoint ||= get_auth_endpoint
  end

  def self.get_auth_endpoint
    q = quantum_credentials
    # "#{q['auth_protocol']}://#{q['auth_host']}:#{q['auth_port']}/v2.0/"
    q['auth_url']
  end

  def self.quantum_file
    return @quantum_file if @quantum_file
    @quantum_file = Puppet::Util::IniConfig::File.new
    @quantum_file.read('/etc/quantum/l3_agent.ini')
    @quantum_file
  end

  def self.auth_quantum(*args)
    begin
      q = quantum_credentials
      quantum('--os-tenant-name', q['admin_tenant_name'], '--os-username', q['admin_user'], '--os-password', q['admin_password'], '--os-auth-url', auth_endpoint, args) if q
    rescue Exception => e
      raise(e)
    end
  end

  def auth_quantum(*args)
    self.class.auth_quantum(args)
  end

  def section
      'DEFAULT'
  end

  def setting
      'router_id'
  end

  def separator
    '='
  end

  def should
	begin
  	    router_info = auth_quantum('router-show', @resource[:name] )
	  if router_info
	    router_id = self.class.get_id(router_info) 
	    router_id.to_s.strip
	  end
	rescue
	  nil	
	end
  end

  def file_path
    '/etc/quantum/l3_agent.ini'
  end
 private
    def self.get_id(router_info)
      router_info.split("\n").grep(/\bid/).to_s.split[3]
    end
end
