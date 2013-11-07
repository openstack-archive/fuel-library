# Quantum common functions
#
require 'puppet/util/inifile'
require 'tempfile'

class Puppet::Provider::Quantum < Puppet::Provider
  def self.prefetch(resources)
    instances.each do |i|
      res = resources[i.name.to_s]
      if ! res.nil?
        res.provider = i
      end
    end
  end

  def self.quantum_credentials
    @quantum_credentials ||= get_quantum_credentials
  end

  def self.get_quantum_credentials
    if quantum_file and quantum_file['keystone_authtoken'] and
    quantum_file['keystone_authtoken']['auth_url'] and
    quantum_file['keystone_authtoken']['admin_tenant_name'] and
    quantum_file['keystone_authtoken']['admin_user'] and
    quantum_file['keystone_authtoken']['admin_password']

      q = {}
      q['auth_url'] = quantum_file['keystone_authtoken']['auth_url'].strip
      q['admin_user'] = quantum_file['keystone_authtoken']['admin_user'].strip
      q['admin_password'] = quantum_file['keystone_authtoken']['admin_password'].strip
      q['admin_tenant_name'] = quantum_file['keystone_authtoken']['admin_tenant_name'].strip
      return q
    else
      # raise(Puppet::Error, 'File: /etc/quantum/api-paste.ini does not contain all required sections.')
      raise(Puppet::Error, 'File: /etc/quantum/quantum.conf does not contain all required sections.')
    end
  end

  def quantum_credentials
    self.class.quantum_credentials
  end

  def self.auth_endpoint
    @auth_endpoint ||= get_auth_endpoint
  end

  def self.get_auth_endpoint
    quantum_credentials()['auth_url']
  end

  def self.quantum_file
    return @quantum_file if @quantum_file
    @quantum_file = Puppet::Util::IniConfig::File.new
    @quantum_file.read('/etc/quantum/quantum.conf')

    @quantum_file
  end

  # def self.quantum_hash
  #   @quantum_hash ||= build_quantum_hash
  # end

  # def quantum_hash
  #   self.class.quantum_hash
  # end

  def self.auth_quantum(*args)
    q = quantum_credentials
    rv = nil
    timeout = 120 # default timeout 2min.
    end_time = Time.now.to_i + timeout
    loop do
      begin
        rv = quantum('--os-tenant-name', q['admin_tenant_name'], '--os-username', q['admin_user'], '--os-password', q['admin_password'], '--os-auth-url', auth_endpoint, args)
        break
      rescue Puppet::ExecutionFailure => e
        if ! e.message =~ /(\(HTTP\s+400\))|
              (400-\{\'message\'\:\s+\'\'\})|
              (\[Errno 111\]\s+Connection\s+refused)|
              (503\s+Service\s+Unavailable)|
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
          wa = end_time - current_time
          Puppet::debug("Non-fatal error: \"#{e.message}\"")
          notice("Quantum API not avalaible. Wait up to #{wa} sec.")
        end
        sleep(2) # do not remove!!! It's a positive brake!
      end
    end
    return rv
  end
  def auth_quantum(*args)
    self.class.auth_quantum(args)
  end

  #private

  def self.list_keystone_tenants
    q = quantum_credentials
    tenants_id = {}
    timeout = 120 # default timeout 2min.
    end_time = Time.now.to_i + timeout
    loop do
      begin
        keystone(
          '--os-tenant-name', q['admin_tenant_name'],
          '--os-username', q['admin_user'],
          '--os-password', q['admin_password'],
          '--os-auth-url', auth_endpoint,
          'tenant-list'
        ).split("\n")[3..-2].collect do |tenant|
            t_id = tenant.split[1]
            t_name = tenant.split[3]
            tenants_id[t_name] = t_id
        end
        break
      rescue Puppet::ExecutionFailure => e
        current_time = Time.now.to_i
        if current_time > end_time
          raise(e)
          #break
        else
          wa = end_time - current_time
          notice("Keystone API not avalaible. Wait up to #{wa} sec.")
        end
        sleep(2) # do not remove!!! It's a positive brake!
      end
    end
    return tenants_id
  end
  # def list_keystone_tenants
  #   self.class.list_keystone_tenants
  # end

end
# vim: set ts=2 sw=2 et :
