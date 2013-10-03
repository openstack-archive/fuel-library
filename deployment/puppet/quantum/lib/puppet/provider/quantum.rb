#
# Quantum common functions
#
require 'puppet/util/inifile'
require 'tempfile'

class Puppet::Provider::Quantum < Puppet::Provider
  def self.quantum_credentials
    @quantum_credentials ||= get_quantum_credentials
  end

  def self.get_quantum_credentials
    # if quantum_file and quantum_file['filter:authtoken'] and
    #   quantum_file['filter:authtoken']['auth_host'] and
    #   quantum_file['filter:authtoken']['auth_port'] and
    #   quantum_file['filter:authtoken']['auth_protocol'] and
    #   quantum_file['filter:authtoken']['admin_tenant_name'] and
    #   quantum_file['filter:authtoken']['admin_user'] and
    #   quantum_file['filter:authtoken']['admin_password']

    if quantum_file and quantum_file['DEFAULT'] and
    quantum_file['DEFAULT']['auth_url'] and
    quantum_file['DEFAULT']['admin_tenant_name'] and
    quantum_file['DEFAULT']['admin_user'] and
    quantum_file['DEFAULT']['admin_password']

      q = {}
      # q['auth_host'] = quantum_file['filter:authtoken']['auth_host'].strip
      # q['auth_port'] = quantum_file['filter:authtoken']['auth_port'].strip
      # q['auth_protocol'] = quantum_file['filter:authtoken']['auth_protocol'].strip
      q['auth_url'] = quantum_file['DEFAULT']['auth_url'].strip
      q['admin_tenant_name'] = quantum_file['DEFAULT']['admin_tenant_name'].strip
      q['admin_user'] = quantum_file['DEFAULT']['admin_user'].strip
      q['admin_password'] = quantum_file['DEFAULT']['admin_password'].strip
      return q
    else
      # raise(Puppet::Error, 'File: /etc/quantum/api-paste.ini does not contain all required sections.')
      raise(Puppet::Error, 'File: /etc/quantum/l3_agent.ini does not contain all required sections.')
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

    # quantum_apipaste = '/etc/quantum/api-paste.ini'
    # tf_apipaste = Tempfile.new('api-paste-ini-')
    #
    # conf_opt = File.open(quantum_apipaste).read

    # inside = false
    # conf_opt.each do |line|
    #   if line.strip == '[filter:authtoken]'
    #     inside = true
    #   elsif inside and line.match(/^\s*\[/)
    #     inside = false
    #   end
    #   tf_apipaste.print line if inside
    # end

    # tf_apipaste.flush

    # @quantum_file = Puppet::Util::IniConfig::File.new
    # @quantum_file.read(tf_apipaste.path)

    # tf_apipaste.close

    @quantum_file = Puppet::Util::IniConfig::File.new
    @quantum_file.read('/etc/quantum/l3_agent.ini')

    @quantum_file
  end

  # def self.quantum_hash
  #   @quantum_hash ||= build_quantum_hash
  # end

  # def quantum_hash
  #   self.class.quantum_hash
  # end

  def self.auth_quantum(*args)
    #todo: Rewrite, using ruby-openstack
    begin
      q = quantum_credentials
    rescue Exception => e
      raise(e)
    end

    # args_str = args.join '` '
    # notice("ARGS: #{args_str}\n")
    rv = nil
    retries = 60
    loop do
      begin
        rv = quantum('--os-tenant-name', q['admin_tenant_name'], '--os-username', q['admin_user'], '--os-password', q['admin_password'], '--os-auth-url', auth_endpoint, args)
        break
      rescue Exception => e
        if e.message =~ /(\(HTTP\s+400\))|(\[Errno 111\]\s+Connection\s+refused)|(503\s+Service\s+Unavailable)|(Max\s+retries\s+exceeded)/
          notice("Can't connect to quantum backend. Waiting for retry...")
          retries -= 1
          sleep 2
          if retries <= 1
            notice("Can't connect to quantum backend. No more retries, auth failed")
            raise(e)
            #break
          end
        else
          raise(e)
          #break
        end
      end
    end
    return rv
  end

  def auth_quantum(*args)
    self.class.auth_quantum(args)
  end

  private
  # def self.list_quantum_objects
  #   ids = []
  #   (auth_quantum('index').split("\n")[2..-1] || []).collect do |line|
  #     ids << line.split[0]
  #   end
  #   return ids
  # end

  # def self.get_quantum_attr(id, attr)
  #   (auth_quantum('show', id).split("\n") || []).collect do |line|
  #     if line =~ /^#{attr}:/
  #       return line.split(': ')[1..-1]
  #     end
  #   end
  # end

  def self.list_keystone_tenants
    q = quantum_credentials
    tenants_id = {}

    keystone(
    '--os-tenant-name', q['admin_tenant_name'],
    '--os-username', q['admin_user'],
    '--os-password', q['admin_password'],
    '--os-auth-url', auth_endpoint,
    #'tenant-list').grep(/\|\s+#{tenant_name}\s+\|/) { |tenant| tenant.split[1] }.to_s
    'tenant-list').split("\n")[3..-2].collect do |tenant|
      tenants_id[tenant.split[3]] = tenant.split[1]
    end

    tenants_id
  end

end
