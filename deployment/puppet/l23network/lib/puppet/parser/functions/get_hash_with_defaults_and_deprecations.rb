module Puppet::Parser::Functions
  newfunction(:get_hash_with_defaults_and_deprecations, :type => :rvalue, :doc => <<-EOS
This function get three hashes:
  * hash with incoming parameters
  * hash with default values
  * hash with deprecations

It's returns a hash
EOS
  ) do |arguments|
    if arguments.size != 3
      raise(Puppet::ParseError, "get_hash_with_defaults_and_deprecations(): Wrong number of arguments " +
        "given (#{arguments.size} for 3)")
    end

    (0..2).each{ |i|
      if ! arguments[i].is_a? Hash
      raise(Puppet::ParseError,
        "#{i}-argument of get_hash_with_defaults_and_deprecations() has wrong type." +
        " Should be a Hash."
      )
      end
    }

    inp, defa, depre = arguments
    rv = Marshal.load(Marshal.dump(inp))

    # Add deprecated properties
    depre.each { |k,v|
      if rv[k].nil? and ![nil, 'undef', :undef].index(v)
        warn("You using deprecated parameter '#{k}':#{v}")
        rv[k] = v
      end
    }

    defa.each { |k,v|
      if rv[k].nil? and ![nil, 'undef', :undef].index(v)
        info("Setup default parameter '#{k}':#{v}")
        rv[k] = v
      end
    }

    return rv
  end
end
