require 'puppet'
require 'puppet/provider/openstack'

class Puppet::Provider::Openstack::Credentials

  KEYS = [
    :auth_url, :password, :project_name, :username,
    :token, :url,
    :identity_api_version
  ]

  KEYS.each { |var| attr_accessor var }

  def self.defined?(name)
    KEYS.include?(name.to_sym)
  end

  def set(key, val)
    if self.class.defined?(key.to_sym)
      self.instance_variable_set("@#{key}".to_sym, val)
    end
  end

  def set?
    return true if user_password_set? || service_token_set?
  end

  def service_token_set?
    return true if @token && @url
  end

  def to_env
    env = {}
    self.instance_variables.each do |var|
      name = var.to_s.sub(/^@/,'OS_').upcase
      env.merge!(name => self.instance_variable_get(var))
    end
    env
  end

  def user_password_set?
    return true if @username && @password && @project_name && @auth_url
  end

  def unset
    KEYS.each do |key|
      if key != :identity_api_version &&
        self.instance_variable_defined?("@#{key}")
        set(key, '')
      end
    end
  end

  def version
    self.class.to_s.sub(/.*V/,'').sub('_','.')
  end
end

class Puppet::Provider::Openstack::CredentialsV2_0 < Puppet::Provider::Openstack::Credentials
end

class Puppet::Provider::Openstack::CredentialsV3 < Puppet::Provider::Openstack::Credentials

  KEYS = [
    :cacert,
    :cert,
    :default_domain,
    :domain_id,
    :domain_name,
    :key,
    :project_domain_id,
    :project_domain_name,
    :project_id,
    :trust_id,
    :user_domain_id,
    :user_domain_name,
    :user_id
  ]

  KEYS.each { |var| attr_accessor var }

  def self.defined?(name)
    KEYS.include?(name.to_sym) || super
  end

  def user_password_set?
    return true if (@username || @user_id) && @password && (@project_name || @project_id) && @auth_url
  end

  def initialize
    set(:identity_api_version, version)
  end
end
