Puppet::Type.newtype(:l2_bridge) do
    @doc = "Manage a Open vSwitch bridge (virtual switch)"
    desc @doc

    ensurable

    MAX_BR_NAME_LENGTH = 15

    newparam(:bridge) do
      isnamevar
      desc "The bridge to configure"
      #
      validate do |val|
        if not val =~ /^[a-z][0-9a-z\.\-\_]*[0-9a-z]$/
          fail("Wrong bridge name: '#{val}'")
        end
      end
    end

    newparam(:skip_existing) do
      defaultto(false)
      desc "Allow to skip existing bridge"
    end

    newproperty(:external_ids) do
      desc "External IDs for the bridge"
    end

    newproperty(:br_type) do
      desc "Internal read-only property"
      validate do |value|
        raise ArgumentError, "You shouldn't change br_type -- it's a internal RO property!"
      end
    end

    # global validator
    def validate
        # require 'pry'
        # binding.pry
        if provider.class.name != :ovs and self[:name].length > MAX_BR_NAME_LENGTH
          # validate name for differetn providers may only in global validator, because
          # 'provider' option don't accessible while validating name
          fail("Wrong bridge name '#{self[:name]}'.\n For provider '#{provider.class.name}' bridge name shouldn't has length more, than #{MAX_BR_NAME_LENGTH}.")
        end
    end

end
# vim: set ts=2 sw=2 et :