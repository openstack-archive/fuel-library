Puppet::Type.newtype(:cfg) do
    @doc = "Manage a key/value pairs in config file"
    desc @doc

    ensurable

    newparam(:key) do
      isnamevar
      desc "Key in config file"
      #
      validate do |kkk|
        if not kkk =~ /^[a-zA-Z][0-9a-zA-Z\.\-\_]*[0-9a-zA-Z]$/
          fail("Invalid key name: '#{kkk}'")
        end
      end
    end

    newproperty(:value) do
      desc "Value, that will be set to key"
    end

    newparam(:key_val_separator_char) do
      defaultto('=')
      desc "key/value separator in cfg file"
    end

    newparam(:comment_char) do
      defaultto('#')
      desc "1st non space char, that say that this line is comment"
    end

    newparam(:file) do
      desc "Config file path"
      #
      validate do |val|
        if not val =~ /^[0-9a-zA-Z\.\-\_\/]*[0-9a-zA-Z]$/
          fail("Invalid file name: '#{val}'")
        end
      end
    end
end
