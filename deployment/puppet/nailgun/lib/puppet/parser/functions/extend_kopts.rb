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

        default_kopts = args[1].split(" ")
        new_kopts = kopts.split(" ")

        hash_default_kopts = {}
        hash_new_kopts = {}

        default_kopts.each do |e|
          key,value = e.split("=")
          hash_default_kopts[key] = value
        end

        new_kopts.each do |e|
          key,value = e.split("=")
          hash_new_kopts[key] = value
        end

        keys_intersection = hash_default_kopts.keys & hash_new_kopts.keys
        merged = hash_default_kopts.dup.update(hash_new_kopts)

        keys_intersection.each do |k|
          merged[k] = hash_new_kopts[k]
        end

        result_kopts = merged.collect {|key, value| value ? "#{key}=#{value}" : "#{key}"}.join(' ')

      end
    return result_kopts
  end
end
