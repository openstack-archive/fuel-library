module MultipleKopts
  # Transform string into hash and provide array of keys:
  # Example:
  # Input data: "first=21 first=12 second=44"
  # Output data: [{ first => "21 12", second => "44"}, [ first, first, second]]
  def self.string_to_hash_with_keys(string)
    hash, option_order = {}, []
    string.to_s.split(' ').each() do |e|
      key, value = e.split("=", 2).map { |i| i.strip()}
      hash[key] = hash.has_key?(key) ? "#{hash[key]} #{value}" : value
      option_order << key
    end
    [hash, option_order]
  end

  # Transform hash into string using key's order from 'keys' array:
  # Example:
  # Input data: { first => "21 12", second => "44"}, [ first, second]
  # Output data: "first=21 first=12 second=44"
  def self.hash_to_string(hash, keys)
    string = ""
    keys.each() do |key|
      value = hash[key]
      opt_string = value.nil? ? key : value.split(' ').map { |e| "#{key}=#{e}" }.join(' ')
      string = "#{string} #{opt_string}"
    end
    string.strip()
  end
end

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

    raise Puppet::ParseError, ("extend_kopts(): wrong number of arguments - #{args.length}, must be 2") unless args.length == 2

    hash_new_kopts, new_kopts_keys = MultipleKopts.string_to_hash_with_keys(args[0])
    hash_default_kopts, default_kopts_keys = MultipleKopts.string_to_hash_with_keys(args[1])

    keys = (new_kopts_keys + default_kopts_keys).uniq()

    return MultipleKopts.hash_to_string(hash_default_kopts.merge(hash_new_kopts), keys)
  end
end
