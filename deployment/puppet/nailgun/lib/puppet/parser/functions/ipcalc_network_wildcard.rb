module Puppet::Parser::Functions
  newfunction(:ipcalc_network_wildcard, :type => :rvalue, :doc => <<-EOS
Returns network wildcard by host ip address and netmask.
    EOS
  ) do |arguments|

    require 'ipaddr'

    if (arguments.size != 2) then
      raise(Puppet::ParseError, "ipcalc_network_wilrdcard(): Wrong number of arguments "+
            "given #{arguments.size} for 2")
    end

    begin
      ip = arguments[0]
      mask = arguments[1]
      address = IPAddr.new("#{ip}/#{mask}")

      class << address
        def mask_length
          @mask_addr.to_s(2).count("1")
        end

        def wildcard_notation
          return unless ipv4?
          octets = mask_length / 8
          pattern = []
          (0...octets).map do |i|
            pattern << ((@addr >> (24 - 8 * i)) & 0xff)
          end
          pattern << '*' if octets < 4
          pattern.join '.'
        end
      end

    return address.wildcard_notation
    rescue ArgumentError
       raise(Puppet::ParseError, "ipcalc_network_wildcard(): bad arguments #{arguments[0]} #{arguments[1]}")
    end
  end
end

