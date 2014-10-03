require 'csv'
require 'puppet/util/inifile'

class Puppet::Provider::Neutron < Puppet::Provider

  #NOTE(xenolog): self.prefetch was removed with comment:
  # FIXME:(xarses) needs to be abstraced from subresources and re-written here

  def self.conf_filename
    '/etc/neutron/neutron.conf'
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

  def self.neutron_credentials
    @neutron_credentials ||= get_neutron_credentials
  end

  def self.get_neutron_credentials
    auth_keys = ['auth_host', 'auth_port', 'auth_protocol',
                 'admin_tenant_name', 'admin_user', 'admin_password']
    conf = neutron_conf
    if conf and conf['keystone_authtoken'] and
        auth_keys.all?{|k| !conf['keystone_authtoken'][k].nil?}
      creds = Hash[ auth_keys.map \
                   { |k| [k, conf['keystone_authtoken'][k].strip] } ]
      if conf['DEFAULT'] and !conf['DEFAULT']['nova_region_name'].nil?
        creds['nova_region_name'] = conf['DEFAULT']['nova_region_name']
      end
      return creds
    else
      raise(Puppet::Error, "File: #{conf_filename} does not contain all \
required sections.  Neutron types will not work if neutron is not \
correctly configured.")
    end
  end

  def neutron_credentials
    self.class.neutron_credentials
  end

  def self.auth_endpoint
    @auth_endpoint ||= get_auth_endpoint
  end

  def self.get_auth_endpoint
    q = neutron_credentials
    "#{q['auth_protocol']}://#{q['auth_host']}:#{q['auth_port']}/v2.0/"
  end

  def self.neutron_conf
    return @neutron_conf if @neutron_conf
    @neutron_conf = Puppet::Util::IniConfig::File.new
    @neutron_conf.read(conf_filename)
    @neutron_conf
  end

  def self.auth_neutron(*args)
    q = neutron_credentials
    authenv = {
      :OS_AUTH_URL    => self.auth_endpoint,
      :OS_USERNAME    => q['admin_user'],
      :OS_TENANT_NAME => q['admin_tenant_name'],
      :OS_PASSWORD    => q['admin_password']
    }
    if q.key?('nova_region_name')
      authenv[:OS_REGION_NAME] = q['nova_region_name']
    end
    # NOTE(bogdando) contribute change to upstream #1384097:
    #   enhanced message checks within a given time frame
    rv = nil
    timeout = 120
    end_time = Time.now.to_i + timeout
    loop do
      begin
        withenv authenv do
          rv = neutron(args)
        end
        break
      rescue Puppet::ExecutionFailure => e
        if ! e.message =~ /(\(HTTP\s+400\))|
              (400-\{\'message\'\:\s+\'\'\})|
              (\[Errno 111\]\s+Connection\s+refused)|
              (503\s+Service\s+Unavailable)|
              (504\s+Gateway\s+Time-out)|
              (\:\s+Maximum\s+attempts\s+reached)|
              (Unauthorized\:\s+bad\s+credentials)|
              (Max\s+retries\s+exceeded)/
          raise(e)
        end
        current_time = Time.now.to_i
        if current_time > end_time
          break
        else
          wait = end_time - current_time
          Puppet::debug("Non-fatal error: \"#{e.message}\"")
          notice("Neutron API not avalaible. Wait up to #{wait} sec.")
        end
        sleep(2)
        # Note(xarses): Don't remove, we know that there is one of the
        # Recoverable erros above, So we will retry a few more times
      end
    end
    return rv
  end

  def auth_neutron(*args)
    self.class.auth_neutron(args)
  end

  def self.reset
    @neutron_conf        = nil
    @neutron_credentials = nil
  end

  def self.list_neutron_resources(type)
    ids = []
    list = auth_neutron("#{type}-list", '--format=csv',
                        '--column=id', '--quote=none')
    # NOTE(bogdando) contribute change to upstream #1384101:
    #   raise Puppet exception, if resources list is empty
    if list.nil?
      raise(Puppet::ExecutionFailure, "Can't prefetch #{type}-list Neutron or Keystone API is not avalaible.")
    end

    (list.split("\n")[1..-1] || []).compact.collect do |line|
      ids << line.strip
    end
    return ids
  end

  def self.get_neutron_resource_attrs(type, id)
    attrs = {}
    net = auth_neutron("#{type}-show", '--format=shell', id)
    # NOTE(bogdando) contribute change to upstream #1384101:
    #   raise Puppet exception, if list of resources' attributes is empty
    if net.nil?
      raise(Puppet::ExecutionFailure, "Can't prefetch #{type}-show Neutron or Keystone API is not avalaible.")
    end
    last_key = nil
    (net.split("\n") || []).compact.collect do |line|
      if line.include? '='
        k, v = line.split('=', 2)
        attrs[k] = v.gsub(/\A"|"\Z/, '')
        last_key = k
      else
        # Handle the case of a list of values
        v = line.gsub(/\A"|"\Z/, '')
        attrs[last_key] = [attrs[last_key], v].flatten
      end
    end
    return attrs
  end

  def self.list_router_ports(router_name_or_id)
    results = []
    cmd_output = auth_neutron("router-port-list",
                              '--format=csv',
                              router_name_or_id)
    if ! cmd_output
      return results
    end

    headers = nil
    CSV.parse(cmd_output) do |row|
      if headers == nil
        headers = row
      else
        result = Hash[*headers.zip(row).flatten]
        match_data = /.*"subnet_id": "(.*)", .*/.match(result['fixed_ips'])
        if match_data
          result['subnet_id'] = match_data[1]
        end
        results << result
      end
    end
    return results
  end

  def self.auth_keystone(*args)
    q = neutron_credentials
    authenv = {
      :OS_AUTH_URL    => self.auth_endpoint,
      :OS_USERNAME    => q['admin_user'],
      :OS_TENANT_NAME => q['admin_tenant_name'],
      :OS_PASSWORD    => q['admin_password']
    }
    if q.key?('nova_region_name')
      authenv[:OS_REGION_NAME] = q['nova_region_name']
    end

    rv = nil
    timeout = 120
    end_time = Time.now.to_i + timeout
    loop do
      begin
        withenv authenv do
          rv = keystone(args)
        end
        break
      rescue Puppet::ExecutionFailure => e
        if ! e.message =~ /(\(HTTP\s+400\))|
              (400-\{\'message\'\:\s+\'\'\})|
              (\[Errno 111\]\s+Connection\s+refused)|
              (503\s+Service\s+Unavailable)|
              (504\s+Gateway\s+Time-out)|
              (\:\s+Maximum\s+attempts\s+reached)|
              (Unauthorized\:\s+bad\s+credentials)|
              (Max\s+retries\s+exceeded)/
          raise(e)
        end
        current_time = Time.now.to_i
        if current_time > end_time
          #raise(e)
          break
        else
          wait = end_time - current_time
          Puppet::debug("Non-fatal error: \"#{e.message}\"")
          notice("Keystone API not avalaible. Wait up to #{wait} sec.")
        end
        sleep(2)
        # Note(xarses): Don't remove, we know that there is one of the
        # Recoverable erros above, So we will retry a few more times
      end
    end
    return rv
  end

  def auth_keystone(*args)
    self.class.auth_neutron(args)
  end

  def self.get_tenant_id(catalog, name)
    rv = nil
    auth_keystone('tenant-list').each do |line|
      fields=line.split(/\s*\|\s*/)
      if fields[1] and fields[1].size == 32
        if fields[2] == name
          rv = fields[1]
          break
        end
      end
    end
    if rv.nil?
      fail("Unable to get tenant-ID for tenant '#{name}'")
    end
    return rv
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
