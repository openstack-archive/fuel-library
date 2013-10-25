Puppet::Type.newtype(:neutron_subnet) do

  @doc = "Manage creation/deletion of neutron subnet/networks"

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The subnet name'
  end

  newparam(:tenant) do
    desc "The tenant that the network is associated with"
    defaultto "admin"
  end

  newparam(:network) do
    desc 'Network id or name this subnet belongs to'
  end

  newparam(:cidr) do
    desc 'CIDR of subnet to create'
  end

  newparam(:ip_version) do
    defaultto 4
  end

  newparam(:gateway) do
  end

  newparam(:enable_dhcp) do
    defaultto "False"
  end

  newparam(:alloc_pool) do
    desc 'Allocation pool IP addresses'
  end

  newparam(:nameservers) do
    defaultto false
    desc 'DNS name servers used by hosts'
    munge do |val|
      if val.is_a?(String)
        if !val.strip.empty?
          val.strip.split(/[:\s+\,\-]/)
        else
          false
        end
      elsif val.is_a?(Array)
        val.empty?  ?  false  : val
      else
        false
      end
    end
  end

  # validate do
  #   raise(Puppet::Error, 'Label must be set') unless self[:label]
  # end

  # Require the neutron service to be running
  # autorequire(:service) do
  #   ['neutron-server']
  # end

  autorequire(:package) do
    ['python-neutronclient']
  end

end
