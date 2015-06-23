Puppet::Type.newtype(:nova_floating_range) do

  @doc = 'Manage creation/deletion of nova floating ip ranges.'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'IP range ("192.168.1.1-192.168.1.55")'

    validate do |value|
      raise Puppet::Error, " #{value} does not look like IP range" unless value =~ /^(\d{1,3}\.){3}\d{1,3}-(\d{1,3}\.){3}\d{1,3}$/
    end
  end

  newparam(:pool) do
    desc 'Pool ranges'

    defaultto 'nova'
  end

  newparam(:interface) do
    # I don't know how use it
    desc 'Interface for floating IP'
  end

  newparam(:username) do
    desc 'authorization user'

    munge do |value|
      String value
    end
  end

  newparam(:api_key) do
    desc 'authorization key'

    munge do |value|
      String value
    end
  end

  newparam(:auth_method) do
    desc 'authorization password'

    munge do |value|
      String value
    end
  end

  newparam(:auth_url) do
    desc 'URL to keystone authorization http://192.168.1.1:5000/v2.0/'

    validate do |value|
      raise Puppet::Error, "#{value} does not look like URL" unless value =~ /^https?:\/\/\S+:\d{1,5}\/v[\d\.]{1,5}\//
    end
  end

  newparam(:authtenant_name) do
    desc 'Tenant name'

    munge do |value|
      String value
    end
  end

  newparam(:api_retries) do
    desc 'number of API reconnect retries'

    validate do |value|
      raise Puppet::Error, "#{value} does not look like numeric" unless value.is_a?(Integer) || value =~ /^\d+$/
    end

    munge do |value|
      Integer value
    end
  end

  newparam(:service_type) do
    desc 'Connection type :service_type parameter to "compute", "object-store", "volume" or "network" (defaults to "compute")'

    defaultto 'compute'

    munge do |value|
      String value
    end
  end

end
