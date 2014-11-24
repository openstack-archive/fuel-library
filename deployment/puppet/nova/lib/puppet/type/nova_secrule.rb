Puppet::Type.newtype(:nova_secrule) do
  desc "Manage nova security rules"

  ensurable
  
  newparam(:name) do
    isnamevar
  end

  newparam(:ip_protocol) do
    defaultto do
      raise Puppet::Error, 'You should give protocol!'
    end
    newvalues 'tcp', 'udp', 'icmp'
  end

  newparam(:from_port) do
    defaultto do
      raise Puppet::Error, 'You should give the source port!'
    end
    validate do |value|
      if value !~ /\d+/ or value.to_i <= 0 or value.to_i >= 65535
        raise Puppet::Error, 'Incorrect from port!'
      end
    end
  end

  newparam(:to_port) do
    defaultto do
      raise Puppet::Error, 'You should give the destination port!'
    end
    validate do |value|
      if value !~ /\d+/ or value.to_i <= 0 or value.to_i >= 65535
        raise Puppet::Error, 'Incorrect to port!'
      end
    end
  end

  newparam(:ip_range) do

    validate do |value|
      def is_cidr_net?(value)
        begin
          address, mask = value.split('/')
          return false unless address and mask
          octets = address.split('.')
          return false unless octets.length == 4

          cidr = true
          octets.each do |octet|
            n = octet.to_i
            cidr = false unless n <= 255
            cidr = false unless n >= 0
            break unless cidr
          end

          cidr = false unless mask.to_i <= 32
          cidr = false unless mask.to_i >= 0
          cidr
        rescue
          false
        end
      end

      raise Puppet::Error, 'Incorrect ip_range!' unless is_cidr_net? value
    end
  end

  newparam(:source_group) do
  end

  newparam(:security_group) do
    defaultto do
      raise Puppet::Error, 'You should provide the secutity group to add this rule to!'
    end
  end

  validate do
    unless !!self[:ip_range] ^ !!self[:source_group]
      raise Puppet::Error, 'You should give either ip_range or source_group. Not none or both!'
    end
    unless self[:from_port].to_i <= self[:to_port].to_i
      raise Puppet::Error, 'From_port should be lesser or equal to to_port!'
    end
  end

end
