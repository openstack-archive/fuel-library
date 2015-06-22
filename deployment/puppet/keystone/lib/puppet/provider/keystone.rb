require 'puppet/util/inifile'
require 'puppet/provider/openstack'
require 'puppet/provider/openstack/auth'
require 'puppet/provider/openstack/credentials'

class Puppet::Provider::Keystone < Puppet::Provider::Openstack

  extend Puppet::Provider::Openstack::Auth

  INI_FILENAME = '/etc/keystone/keystone.conf'

  def self.get_endpoint
    endpoint = nil
    if ENV['OS_AUTH_URL']
      endpoint = ENV['OS_AUTH_URL']
    else
      endpoint = get_os_vars_from_rcfile(rc_filename)['OS_AUTH_URL']
      unless endpoint
        # This is from legacy but seems wrong, we want auth_url not url!
        endpoint = get_admin_endpoint
      end
    end
    unless endpoint
      raise(Puppet::Error::OpenstackAuthInputError, 'Could not find auth url to check user password.')
    end
    endpoint
  end

  def self.admin_endpoint
    @admin_endpoint ||= get_admin_endpoint
  end

  def self.admin_token
    @admin_token ||= get_admin_token
  end

  def self.get_admin_token
    if keystone_file and keystone_file['DEFAULT'] and keystone_file['DEFAULT']['admin_token']
      return "#{keystone_file['DEFAULT']['admin_token'].strip}"
    else
      return nil
    end
  end

  def self.get_admin_endpoint
    if keystone_file
      if keystone_file['DEFAULT']
        if keystone_file['DEFAULT']['admin_endpoint']
          auth_url = keystone_file['DEFAULT']['admin_endpoint'].strip.chomp('/')
          return "#{auth_url}/v#{@credentials.version}/"
        end

        if keystone_file['DEFAULT']['admin_port']
          admin_port = keystone_file['DEFAULT']['admin_port'].strip
        else
          admin_port = '35357'
        end

        if keystone_file['DEFAULT']['admin_bind_host']
          host = keystone_file['DEFAULT']['admin_bind_host'].strip
          if host == "0.0.0.0"
            host = "127.0.0.1"
          elsif host == '::0'
            host = '[::1]'
          end
        else
          host = "127.0.0.1"
        end
      end

      if keystone_file['ssl'] && keystone_file['ssl']['enable'] && keystone_file['ssl']['enable'].strip.downcase == 'true'
        protocol = 'https'
      else
        protocol = 'http'
      end
    end

    "#{protocol}://#{host}:#{admin_port}/v#{@credentials.version}/"
  end

  def self.request(service, action, properties=nil)
    super
    rescue Puppet::Error::OpenstackAuthInputError => error
      request_by_service_token(service, action, error, properties)
  end

  def self.request_by_service_token(service, action, error, properties=nil)
    properties ||= []
    @credentials.token = get_admin_token
    @credentials.url   = get_admin_endpoint
    raise error unless @credentials.service_token_set?
    Puppet::Provider::Openstack.request(service, action, properties, @credentials)
  end

  def self.ini_filename
    INI_FILENAME
  end

  def self.keystone_file
    return @keystone_file if @keystone_file
    if File.exists?(ini_filename)
      @keystone_file = Puppet::Util::IniConfig::File.new
      @keystone_file.read(ini_filename)
      @keystone_file
    end
  end

  # Helper functions to use on the pre-validated enabled field
  def bool_to_sym(bool)
    bool == true ? :true : :false
  end

  def sym_to_bool(sym)
    sym == :true ? true : false
  end
end
