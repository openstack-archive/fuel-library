require 'csv'
require 'puppet/util/inifile'

class Puppet::Provider::Ironic < Puppet::Provider

  def self.conf_filename
    '/etc/ironic/ironic.conf'
  end

  def self.withenv(hash, &block)
    saved = ENV.to_hash
    hash.each do |name, val|
      ENV[name.to_s] = val
    end

    yield
  ensure
    ENV.clear
    saved.each do |name, val|
      ENV[name] = val
    end
  end

  def self.ironic_credentials
    @ironic_credentials ||= get_ironic_credentials
  end

  def self.get_ironic_credentials
    auth_keys = ['auth_host', 'auth_port', 'auth_protocol',
                 'admin_tenant_name', 'admin_user', 'admin_password']
    conf = ironic_conf
    if conf and conf['keystone_authtoken'] and
        auth_keys.all?{|k| !conf['keystone_authtoken'][k].nil?}
      return Hash[ auth_keys.map \
                   { |k| [k, conf['keystone_authtoken'][k].strip] } ]
    else
      raise(Puppet::Error, "File: #{conf_filename} does not contain all \
required sections.  Ironic types will not work if ironic is not \
correctly configured.")
    end
  end

  def ironic_credentials
    self.class.ironic_credentials
  end

  def self.auth_endpoint
    @auth_endpoint ||= get_auth_endpoint
  end

  def self.get_auth_endpoint
    q = ironic_credentials
    "#{q['auth_protocol']}://#{q['auth_host']}:#{q['auth_port']}/v2.0/"
  end

  def self.ironic_conf
    return @ironic_conf if @ironic_conf
    @ironic_conf = Puppet::Util::IniConfig::File.new
    @ironic_conf.read(conf_filename)
    @ironic_conf
  end

  def self.auth_ironic(*args)
    q = ironic_credentials
    authenv = {
      :OS_AUTH_URL    => self.auth_endpoint,
      :OS_USERNAME    => q['admin_user'],
      :OS_TENANT_NAME => q['admin_tenant_name'],
      :OS_PASSWORD    => q['admin_password']
    }
    begin
      withenv authenv do
        ironic(args)
      end
    rescue Exception => e
      if (e.message =~ /\[Errno 111\] Connection refused/) or
          (e.message =~ /\(HTTP 400\)/)
        sleep 10
        withenv authenv do
          ironic(args)
        end
      else
       raise(e)
      end
    end
  end

  def auth_ironic(*args)
    self.class.auth_ironic(args)
  end

  def self.reset
    @ironic_conf        = nil
    @ironic_credentials = nil
  end

  def self.list_ironic_resources(type)
    ids = []
    list = auth_ironic("#{type}-list", '--format=csv',
                        '--column=id', '--quote=none')
    (list.split("\n")[1..-1] || []).compact.collect do |line|
      ids << line.strip
    end
    return ids
  end

  def self.get_ironic_resource_attrs(type, id)
    attrs = {}
    net = auth_ironic("#{type}-show", '--format=shell', id)
    last_key = nil
    (net.split("\n") || []).compact.collect do |line|
      if line.include? '='
        k, v = line.split('=', 2)
        attrs[k] = v.gsub(/\A"|"\Z/, '')
        last_key = k
      else
        # Handle the case of a list of values
        v = line.gsub(/\A"|"\Z/, '')
        attrs[last_key] = [attrs[last_key], v]
      end
    end
    return attrs
  end

  def self.get_tenant_id(catalog, name)
    instance_type = 'keystone_tenant'
    instance = catalog.resource("#{instance_type.capitalize!}[#{name}]")
    if ! instance
      instance = Puppet::Type.type(instance_type).instances.find do |i|
        i.provider.name == name
      end
    end
    if instance
      return instance.provider.id
    else
      fail("Unable to find #{instance_type} for name #{name}")
    end
  end

  def self.parse_creation_output(data)
    hash = {}
    data.split("\n").compact.each do |line|
      if line.include? '='
        hash[line.split('=').first] = line.split('=', 2)[1].gsub(/\A"|"\Z/, '')
      end
    end
    hash
  end

end
