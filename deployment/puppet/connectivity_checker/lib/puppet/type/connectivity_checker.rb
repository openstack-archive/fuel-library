Puppet::Type.newtype(:connectivity_checker) do
  desc  'Ping an neighboor host\'s IPs through each existing network'

  newparam(:name) do
    desc 'Resource name. fake parameter.'
    isnamevar
  end

  newproperty(:ensure) do
    newvalues :present, :absent
    defaultto :present
  end

  newparam(:network_scheme) do
    desc 'Actual network_scheme hash from Hiera'
  end

  newparam(:network_metadata) do
    desc 'Actual network_metadata hash from Hiera'
  end

  newparam(:non_destructive) do
    desc "Define whether we should fail on connectivity issues"
    newvalues(:true, :yes, :on, :false, :no, :off)
    aliasvalue(:yes, :true)
    aliasvalue(:on,  :true)
    aliasvalue(:no,  :false)
    aliasvalue(:off, :false)
    defaultto :false
  end

  newparam(:ping_tries) do
    desc "How tries to ping should be for success"
    defaultto 5
    validate do |val|
      if val.to_i <= 0
        raise ArgumentError, "ping_tries should be positive integer, not an '#{val}'"
      end
    end
    munge do |val|
      if val.to_i <= 5
        val = 5
      end
      return val.to_i
    end
  end

  newparam(:ping_timeout) do
    desc "Timeout for each ping call"
    defaultto 20
    validate do |val|
      if val.to_i <= 0
        raise ArgumentError, "ping_timeout should be positive integer, not an '#{val}'"
      end
    end
  end

  # Up to future usage, check connectivity by huge packets, closest to
  # interface MTU with noDF flag
  #
  # newparam(:use_huge_packets) do
  #   desc "Whether to bring the interface up"
  #   newvalues(:true, :yes, :on, :false, :no, :off)
  #   aliasvalue(:yes, :true)
  #   aliasvalue(:on,  :true)
  #   aliasvalue(:no,  :false)
  #   aliasvalue(:off, :false)
  #   defaultto :false
  # end
  #
  # newparam(:fix_source_ipaddr) do
  #   desc "Whether the source IP should be fixed up to primary interface ipaddr"
  #   newvalues(:true, :yes, :on, :false, :no, :off)
  #   aliasvalue(:yes, :true)
  #   aliasvalue(:on,  :true)
  #   aliasvalue(:no,  :false)
  #   aliasvalue(:off, :false)
  #   defaultto :false
  # end

end