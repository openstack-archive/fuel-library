#
require 'puppet/property/boolean'

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
      validate do |val|
        if ! val.is_a? Hash
          fail("External_ids should be a hash!")
        end
      end
      def should_to_s(value)
        rv = []
        value.keys.sort.each do |key|
          rv << "(#{key.to_s}=#{value[key]})"
        end
        rv.join(', ')
      end

      def is_to_s(value)
        should_to_s(value)
      end

      def insync?(value)
        should_to_s(value) == should_to_s(should)
      end
    end

    newproperty(:br_type) do
      desc "Internal read-only property"
      validate do |value|
        raise ArgumentError, "You shouldn't change br_type -- it's a internal RO property!"
      end
    end

    newproperty(:stp, :parent => Puppet::Property::Boolean) do
      desc "Whether stp enable"
      defaultto :true
    end

    newproperty(:vendor_specific) do
      desc "Hash of vendor specific properties"
      defaultto {}
      # provider-specific hash, validating only by type.
      validate do |val|
        if ! val.is_a? Hash
          fail("Vendor_specific should be a hash!")
        end
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