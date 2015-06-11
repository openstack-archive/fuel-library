require 'puppet'
require 'puppet/feature/aviator'
require 'puppet/util/inifile'

class Puppet::Provider::Aviator < Puppet::Provider

  def session
    @session ||= authenticate(resource[:auth], resource[:log_file])
  end

  def self.session
    @session ||= authenticate(nil, nil)
  end

  def request(service, request, &block)
    self.class.make_request(service, request, session_data, &block)
  end

  def self.request(service, request, &block)
    self.make_request(service, request, session_data, &block)
  end

  # needed for tests
  def session_data
    @session_data
  end

  def self.session_data
    @session_data
  end

  def session_data=(data)
    @session_data=data
  end

  def self.session_data=(data)
    @session_data=data
  end

  private

  # Attempt to find credentials in this order:
  # 1. username,password,tenant,host set in type parameters
  # 2. openrc file path set in type parameters
  # 3. service token and host set in type parameters
  # 4. username,password,tenant,host set in environment variables
  # 5. service token and host set in keystone.conf (backwards compatible version)
  def authenticate(auth_params, log_file)
    auth_params ||= {}
    if password_credentials_set?(auth_params)
      @session = get_authenticated_session(auth_params, log_file)

    elsif openrc_set?(auth_params)
      credentials = get_credentials_from_openrc(auth_params['openrc'])
      @session = get_authenticated_session(credentials, log_file)

    elsif service_credentials_set?(auth_params)
      session_hash = get_unauthenticated_session(auth_params, log_file)
      @session_data = session_hash[:data]
      @session = session_hash[:session]

    elsif env_vars_set?
      credentials = get_credentials_from_env
      @session = get_authenticated_session(credentials, log_file)

    else  # Last effort: try to get the token from keystone.conf
      session_hash = self.class.try_auth_with_token(keystone_file, log_file)
      @session_data = session_hash[:data]
      @session = session_hash[:session]
    end
  end

  def self.authenticate(auth_params, log_file)
    auth_params = {} unless auth_params
    if env_vars_set?
      credentials = get_credentials_from_env
      @session = get_authenticated_session(credentials, log_file)

    else  # Last effort: try to get the token from keystone.conf
      session_hash = try_auth_with_token(keystone_file, log_file)
      @session_data = session_hash[:data]
      @session = session_hash[:session]
    end
  end


  def self.try_auth_with_token(conf_file, log_file)
    service_token = get_admin_token_from_keystone_file(conf_file)
    auth_url = get_auth_url_from_keystone_file(conf_file)
    session_hash = {}
    if service_token
      credentials = {
        'service_token' => service_token,
        'host_uri'      => auth_url,
      }
      session_hash = get_unauthenticated_session(credentials, log_file)
    else  # All authentication efforts failed
      raise(Puppet::Error, 'No credentials provided.')
    end
  end


  def self.make_request(service, request, session_data, &block)
    response = nil
    if service && service.default_session_data
      response = service.request(request, :endpoint_type => 'admin') do |params|
        yield(params) if block
      end
    elsif session_data
      response = service.request(request, :endpoint_type => 'admin',
                                 :session_data => session_data) do |params|
        yield(params) if block
      end
    else
      raise(Puppet::Error, 'Cannot make a request with no session data.')
    end
    if response.body.hash['error']
      raise(Puppet::Error, "Error making request: #{response.body.hash['error']['code']} #{response.body.hash['error']['title']}")
    end
    response
  end


  def password_credentials_set?(auth_params)
    auth_params['username'] && auth_params['password'] && auth_params['tenant_name'] && auth_params['host_uri']
  end


  def openrc_set?(auth_params)
    auth_params['openrc']
  end


  def service_credentials_set?(auth_params)
    auth_params['service_token'] && auth_params['host_uri']
  end


  def self.env_vars_set?
    ENV['OS_USERNAME'] && ENV['OS_PASSWORD'] && ENV['OS_TENANT_NAME'] && ENV['OS_AUTH_URL']
  end


  def env_vars_set?
    self.class.env_vars_set?
  end


  def get_credentials_from_openrc(file)
    creds = {}
    begin
      File.open(file).readlines.delete_if{|l| l=~ /^#/}.each do |line|
        key, value = line.split('=')
        key = key.split(' ').last
        value = value.chomp.gsub(/'/, '')
        creds[key] = value
      end
      return creds
    rescue Exception => error
      return {}
    end
  end


  def self.get_credentials_from_env
    ENV.to_hash.dup.delete_if { |key, _| ! (key =~ /^OS/) } # Ruby 1.8.7
  end

  def get_credentials_from_env
    self.class.get_credentials_from_env
  end


  def self.keystone_file
    keystone_file = Puppet::Util::IniConfig::File.new
    keystone_file.read('/etc/keystone/keystone.conf')
    keystone_file
  end

  def keystone_file
    return @keystone_file if @keystone_file
    @keystone_file = Puppet::Util::IniConfig::File.new
    @keystone_file.read('/etc/keystone/keystone.conf')
    @keystone_file
  end


  def self.get_admin_token_from_keystone_file(conf_file)
    if conf_file and conf_file['DEFAULT'] and conf_file['DEFAULT']['admin_token']
      return "#{conf_file['DEFAULT']['admin_token'].strip}"
    else
      return nil
    end
  end

  def get_admin_token_from_keystone_file
    conf_file = keystone_file
    self.class.get_admin_token_from_keystone_file(conf_file)
  end


  def self.get_auth_url_from_keystone_file(conf_file)
    if conf_file
      if conf_file['DEFAULT']
        if conf_file['DEFAULT']['admin_endpoint']
          auth_url = conf_file['DEFAULT']['admin_endpoint'].strip
          return versioned_endpoint(auth_url)
        end

        if conf_file['DEFAULT']['admin_port']
          admin_port = conf_file['DEFAULT']['admin_port'].strip
        else
          admin_port = '35357'
        end

        if conf_file['DEFAULT']['admin_bind_host']
          host = conf_file['DEFAULT']['admin_bind_host'].strip
          if host == "0.0.0.0"
            host = "127.0.0.1"
          end
        else
          host = "127.0.0.1"
        end
      end

      if conf_file['ssl'] && conf_file['ssl']['enable'] && conf_file['ssl']['enable'].strip.downcase == 'true'
        protocol = 'https'
      else
        protocol = 'http'
      end
    end

    "#{protocol}://#{host}:#{admin_port}/v2.0/"
  end

  def get_auth_url_from_keystone_file
    self.class.get_auth_url_from_keystone_file(keystone_file)
  end


  def self.make_configuration(credentials)
    host_uri = versioned_endpoint(credentials['host_uri'] || credentials['OS_AUTH_URL'], credentials['api_version'])
    {
      :provider => 'openstack',
      :auth_service => {
        :name        => 'identity',
        :host_uri    => host_uri,
        :request     => 'create_token',
        :validator   => 'list_tenants',
      },
      :auth_credentials => {
        :username    => credentials['username'] || credentials['OS_USERNAME'],
        :password    => credentials['password'] || credentials['OS_PASSWORD'],
        :tenant_name => credentials['tenant_name'] || credentials['OS_TENANT_NAME']
      }
    }
  end


  def self.get_authenticated_session(credentials, log_file)
    configuration = make_configuration(credentials)
    session = ::Aviator::Session.new(:config => configuration, :log_file => log_file)
    session.authenticate
    session
  end

  def get_authenticated_session(credentials, log_file)
    self.class.get_authenticated_session(credentials, log_file)
  end


  def self.get_unauthenticated_session(credentials, log_file)
    configuration = {
      :provider => 'openstack',
    }
    session_data = {
      :base_url      => credentials['host_uri'],
      :service_token => credentials['service_token']
    }
    session = ::Aviator::Session.new(:config => configuration, :log_file => log_file)
    { :session => session, :data => session_data }
  end

  def get_unauthenticated_session(credentials, log_file)
    self.class.get_unauthenticated_session(credentials, log_file)
  end


  def self.versioned_endpoint(endpoint, version = 'v2.0')
    version = 'v2.0' if version.nil?
    if endpoint =~ /\/#{version}\/?$/ || endpoint =~ /\/v2.0\/?$/ || endpoint =~ /\/v3\/?$/
      endpoint
    else
      "#{endpoint.chomp('/')}/#{version}"
    end
  end
end
