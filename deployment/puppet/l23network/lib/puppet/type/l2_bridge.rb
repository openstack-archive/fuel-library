#
Puppet::Type.newtype(:l2_bridge) do
    @doc = "Manage a native linux and open vSwitch bridges (virtual switches)"
    desc @doc

    ensurable

    MAX_BR_NAME_LENGTH = 15

    newparam(:bridge) do
      isnamevar
      desc "The bridge to configure"
      #
      validate do |val|
        err = "Wrong bridge name:"
        if not val =~ /^[a-z][0-9a-z\-]*[0-9a-z]$/
          fail("#{err} '#{val}'")
        end
        if val.length > 15
          fail("#{err} Name too long: '#{val}'. Allowed not more 15 chars.")
        end
        if ! [Regexp.new(/^bond.*/),
              Regexp.new(/^wlan.*/),
              Regexp.new(/^lo\d*/),
              Regexp.new(/^eth.*/),
              Regexp.new(/^en[ospx]\h+/),
              Regexp.new(/^em\d*/),
              Regexp.new(/^p\d+p\d+/),
              Regexp.new(/^ib[\h\.]*/),
        ].select{|x| x.match(val)}.empty?
          fail("#{err} '#{val}'")
        end
      end
    end

    newparam(:use_ovs) do
      desc "Whether using OVS comandline tools"
      newvalues(:true, :yes, :on, :false, :no, :off)
      aliasvalue(:yes, :true)
      aliasvalue(:on,  :true)
      aliasvalue(:no,  :false)
      aliasvalue(:off, :false)
      defaultto :true
    end

    newproperty(:external_ids) do
      desc "External IDs for the bridge"
      #defaultto {}  # do not use defaultto here!!!

      validate do |val|
        if ! val.is_a? Hash
          fail("External_ids should be a hash!")
        end
      end
      def should_to_s(value)
        return [] if value == :absent
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

    newproperty(:stp) do
      desc "Whether stp enable"
      newvalues(:true, :yes, :on, :false, :no, :off)
      aliasvalue(:yes, :true)
      aliasvalue(:on,  :true)
      aliasvalue(:no,  :false)
      aliasvalue(:off, :false)
      defaultto :false
    end

    newproperty(:vendor_specific) do
      desc "Hash of vendor specific properties"
      #defaultto {}  # no default value should be!!!
      # provider-specific properties, can be validating only by provider.
      validate do |val|
        if ! val.is_a? Hash
          fail("Vendor_specific should be a hash!")
        end
      end

      munge do |value|
        (value.empty?  ?  nil  :  L23network.reccursive_sanitize_hash(value))
      end

      def should_to_s(value)
        "\n#{value.to_yaml}\n"
      end

      def is_to_s(value)
        "\n#{value.to_yaml}\n"
      end

      def insync?(value)
        should_to_s(value) == should_to_s(should)
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
