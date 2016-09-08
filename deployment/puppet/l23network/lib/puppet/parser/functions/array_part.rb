module Puppet::Parser::Functions
  newfunction(:array_part, :type => :rvalue, :doc => <<-EOS
This function get array, start and end positions 
and return sub-array between it. 

*Examples:*

    array_part(['a','b','c','d'], 1, 3)

Would result in: ['b','c','d']
    EOS
  ) do |arguments|
    if arguments.size != 3
      raise(Puppet::ParseError, "array_part(): Wrong number of arguments " +
        "given (#{arguments.size} for 3)") 
    end

    in_array = arguments[0]
    p_start  = arguments[1].to_i()
    p_end    = arguments[2].to_i()

    if ! in_array.is_a?(Array)
      raise(Puppet::ParseError, 'array_part(): Requires array as first argument.')
    end
    if (in_array.length == 0) or (p_start < 0) or (p_start > in_array.length-1)
      return nil
    end
    if (p_end == 0) or (p_end > in_array.length-1)
      p_end = in_array.length-1
    end
    if (p_end < p_start) 
      raise(Puppet::ParseError, 'array_part(): Ranges out of Array indexes.')
    end

    if p_start == p_end
      return Array(in_array[p_start])
    end

    return in_array[p_start..p_end]
  end
end

# vim: set ts=2 sw=2 et :
