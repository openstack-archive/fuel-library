module Puppet::Parser::Functions
  newfunction(:extend_kopts, :type => :rvalue, :doc => <<-EOS
    This function changes "kopts" parameter if user modified it
    and return the string. It takes two arguments: string from
    metadata.yaml from "extend_kopts" option and default string
    in format "key1=value1 key2=value2 key3".
    For example:

    $metadata = loadyaml('path/to/metadata.yaml')
    extend_kopts($metadata['extend_kopts'], 'key1=a key2=b")

    Function compare two strings, make changes into default option
    and return it.

    So, if in the /path/to/metadata.yaml in the "extend_kopts" will be
    "key3=c key4 key1=not_a", we will get in the output:
    "key2=b key3=c key4 key1=not_a".
  EOS
  ) do |args|

      begin

        unless args.length == 2
          raise Puppet::ParseError, ("extend_kopts(): wrong number of arguments - #{args.length}, must be 2")
        end

        hash_new_kopts = Hash[*args[0].scan(/([^=\s]+)=*([^\s]*)/).flatten]
        hash_default_kopts = Hash[*args[1].scan(/([^=\s]+)=*([^\s]*)/).flatten]

        new_default_kopts = hash_default_kopts.merge(hash_new_kopts)
        empty_values = lambda {|v| v.empty? ? nil : v}
        merged = new_default_kopts.update(new_default_kopts) {|k,v| empty_values.call(v)}
        result_kopts = merged.collect {|key, value| value ? "#{key}=#{value}" : "#{key}"}.join(' ')

      end
    return result_kopts
  end
end
