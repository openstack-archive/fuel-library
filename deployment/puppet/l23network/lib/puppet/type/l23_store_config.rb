Puppet::Type.newtype(:l23_store_config) do
    @doc = "Manage lines by key/value pairs in config file"
    desc @doc

    ensurable

    newparam(:file) do
      desc "Config file name (not full path)"
      #
      validate do |val|
        if not val =~ /^[a-zA-Z][0-9a-zA-Z\.\-\_\/]*[0-9a-zA-Z]$/
          fail("Invalid file name: '#{val}'")
        end
      end
    end

    newproperty(:config) do
      defaultto({})
      desc "Key/value hash for inserting to config file"
      #
      validate do |cfghash|
        cfghash.each_pair do |k,v|
          if not k =~ /^[a-zA-Z][0-9a-zA-Z\.\-\_]*[0-9a-zA-Z]$/
            fail("Invalid key name: '#{k}'")
          end
        end
      end
    end

end
