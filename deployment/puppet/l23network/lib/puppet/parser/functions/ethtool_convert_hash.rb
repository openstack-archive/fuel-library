#
# ethtool_convert_hash.rb
#

module Puppet::Parser::Functions
  newfunction(:ethtool_convert_hash, :type => :rvalue, :doc => <<-EOS
This function get hash of ethtool rules and sanitize it.

*Examples:*

    ethtool_convert_hash({
      :K => [
              'gso off',
              'gro off'
            ],
      :set-channels => [
               'rx 1',
               'tx 2',
               'other 3',
            ]
    })

    should returns:

    {
      '-K' => 'gso off  gro off',
      '--set-channels' => 'rx 1  tx 2  other 3'
    }
    EOS
  ) do |arguments|
    raise(Puppet::ParseError, "ethtool_convert_hash(): Wrong number of arguments " +
      "given (#{arguments.size} for 1)") if arguments.size != 1
    raise(Puppet::ParseError, "ethtool_convert_hash(): Wrong argument type -- " +
      "Should be a Hash.") if ! arguments[0].is_a?(Hash)

    rv = {}

    arguments[0].each do |key, body|
      rkey = key.to_s()
      rkey = rkey.size()==1  ?  "-#{rkey.upcase}"  :  "--#{rkey}"
      if body.is_a?(String)
        rbody = body
      elsif body.is_a?(Array) and body.size() > 0
        rbody = []
        body.each do |ll|
          if ll.is_a?(String)
            rbody.insert(-1,ll.strip())
          else
            aise(Puppet::ParseError, 'ethtool_convert_hash(): Ethtool each parameter should be a String.')
          end
        end
        rbody = rbody.join('  ')
      else
        raise(Puppet::ParseError, 'ethtool_convert_hash(): Ethtool parameters should be represented as String or non-empty Array.')
      end
      rv[rkey] = rbody
    end
    return rv
  end
end

# vim: set ts=2 sw=2 et :
