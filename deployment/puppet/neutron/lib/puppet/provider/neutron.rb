# Neutron common functions
#
require 'puppet/util/inifile'
require 'tempfile'

class Puppet::Provider::Neutron < Puppet::Provider

  def self.neutron_credentials
    @neutron_credentials ||= get_neutron_credentials
  end

  def self.get_neutron_credentials
    if neutron_file and neutron_file['keystone_authtoken'] and
    neutron_file['keystone_authtoken']['auth_url'] and
    neutron_file['keystone_authtoken']['admin_tenant_name'] and
    neutron_file['keystone_authtoken']['admin_user'] and
    neutron_file['keystone_authtoken']['admin_password']

      q = {}
      q['auth_url'] = neutron_file['keystone_authtoken']['auth_url'].strip
      q['admin_user'] = neutron_file['keystone_authtoken']['admin_user'].strip
      q['admin_password'] = neutron_file['keystone_authtoken']['admin_password'].strip
      q['admin_tenant_name'] = neutron_file['keystone_authtoken']['admin_tenant_name'].strip
      return q
    else
      # raise(Puppet::Error, 'File: /etc/neutron/api-paste.ini does not contain all required sections.')
      raise(Puppet::Error, 'File: /etc/neutron/neutron.conf does not contain all required sections.')
    end
  end

  def neutron_credentials
    self.class.neutron_credentials
  end

  def self.auth_endpoint
    @auth_endpoint ||= get_auth_endpoint
  end

  def self.get_auth_endpoint
    neutron_credentials()['auth_url']
  end

  def self.neutron_file
    return @neutron_file if @neutron_file
    @neutron_file = Puppet::Util::IniConfig::File.new
    @neutron_file.read('/etc/neutron/neutron.conf')

    @neutron_file
  end

  # def self.neutron_hash
  #   @neutron_hash ||= build_neutron_hash
  # end

  # def neutron_hash
  #   self.class.neutron_hash
  # end

  def self.auth_neutron(*args)
    #todo: Rewrite, using ruby-openstack
    begin
      q = neutron_credentials
    rescue Exception => e
      raise(e)
    end

    # args_str = args.join '` '
    # notice("ARGS: #{args_str}\n")
    rv = nil
    retries = 60
    loop do
      begin
        rv = neutron('--os-tenant-name', q['admin_tenant_name'], '--os-username', q['admin_user'], '--os-password', q['admin_password'], '--os-auth-url', auth_endpoint, args)
        break
      rescue Exception => e
        if e.message =~ /(\(HTTP\s+400\))|(\[Errno 111\]\s+Connection\s+refused)|(503\s+Service\s+Unavailable)|(Max\s+retries\s+exceeded)/
          notice("Can't connect to neutron backend. Waiting for retry...")
          retries -= 1
          sleep 2
          if retries <= 1
            notice("Can't connect to neutron backend. No more retries, auth failed")
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

  def auth_neutron(*args)
    self.class.auth_neutron(args)
  end

  #todo: rewrite through API
  def check_neutron_api_availability(timeout)
    if timeout.to_i < 1
      timeout = 45 # default timeout 45sec.
    end
    end_time = Time.now.to_i + timeout
    rv = false
    loop do
      begin
        auth_neutron('net-list')
        rv = true
        break
      rescue Puppet::ExecutionFailure => e
        current_time = Time.now.to_i
        if current_time > end_time
          break
        else
          wa = end_time - current_time
          notice("Neutron API not avalaible. Wait up to #{wa} sec.")
        end
        sleep(0.5) # do not remove!!! It's a positive brake!
      end
    end
    return rv
  end


  #private

  def self.list_keystone_tenants
    q = neutron_credentials
    tenants_id = {}

    keystone(
    '--os-tenant-name', q['admin_tenant_name'],
    '--os-username', q['admin_user'],
    '--os-password', q['admin_password'],
    '--os-auth-url', auth_endpoint,
    'tenant-list').split("\n")[3..-2].collect do |tenant|
      t_id = tenant.split[1]
      t_name = tenant.split[3]
      tenants_id[t_name] = t_id
    end

    tenants_id
  end
  # def list_keystone_tenants
  #   self.class.list_keystone_tenants
  # end

end
# vim: set ts=2 sw=2 et :