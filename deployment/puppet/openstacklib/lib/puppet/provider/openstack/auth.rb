require 'puppet/provider/openstack/credentials'

module Puppet::Provider::Openstack::Auth

  RCFILENAME = "#{ENV['HOME']}/openrc"

  def get_os_vars_from_env
    env = {}
    ENV.each { |k,v| env.merge!(k => v) if k =~ /^OS_/ }
    return env
  end

  def get_os_vars_from_rcfile(filename)
    env = {}
    if File.exists?(filename)
      File.open(filename).readlines.delete_if{|l| l=~ /^#|^$/ }.each do |line|
        key, value = line.split('=')
        key = key.split(' ').last
        value = value.chomp.gsub(/'/, '')
        env.merge!(key => value) if key =~ /OS_/
      end
    end
    return env
  end

  def rc_filename
    RCFILENAME
  end

  def request(service, action, properties=nil)
    properties ||= []
    set_credentials(@credentials, get_os_vars_from_env)
    unless @credentials.set?
      @credentials.unset
      set_credentials(@credentials, get_os_vars_from_rcfile(rc_filename))
    end
    unless @credentials.set?
      raise(Puppet::Error::OpenstackAuthInputError, 'Insufficient credentials to authenticate')
    end
    super(service, action, properties, @credentials)
  end

  def set_credentials(creds, env)
    env.each do |key, val|
      var = key.sub(/^OS_/,'').downcase
      creds.set(var, val)
    end
  end
end
