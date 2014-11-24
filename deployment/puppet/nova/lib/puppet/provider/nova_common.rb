require 'openstack'

class Puppet::Provider::Nova_common < Puppet::Provider
  RETRY_COUNT = 100
  RETRY_STEP  = 6

  def auth_username
    @resource[:auth_username]
  end

  def auth_password
    @resource[:auth_password]
  end

  def auth_tenant
    @resource[:auth_tenant]
  end

  def auth_url
    @resource[:auth_url]
  end

  def secgroup_name
    fail 'You should define secgroup_name!'
  end

  def retry_until_success
    RETRY_COUNT.times do |n|
      begin
        out = yield
      rescue => e
        debug "Block failed: #{e.message} Retry #{n}"
        sleep RETRY_STEP
      else
        return out
      end
    end
    fail "Timeout after #{RETRY_COUNT * RETRY_STEP} seconds!"
  end

  # @returns [OpenStack::Connection]
  def connection
    return @connection if @connection
    debug "Connecting to OpenStack with '#{auth_url}' auth_url"
    @connection = retry_until_success do
      connection = OpenStack::Connection.create({
        :username        => auth_username,
        :api_key         => auth_password,
        :auth_method     =>"password",
        :auth_url        => auth_url,
        :authtenant_name => auth_tenant,
        :service_type    => "compute",
      })
      connection.servers
      connection
    end
  end

  def disconnect
    @connection = nil
  end

  # @returns [Hash<Symbol => String>]
  def secgroup
    begin
      connection.security_groups.each do |uuid, group|
        return group if group[:name] == secgroup_name
      end
      nil
    rescue
      nil
    end
  end

  # @returns [Array<Hash>] the array of secgroup_rules hashes
  def rules
    return unless secgroup
    secgroup[:rules]
  end

end
