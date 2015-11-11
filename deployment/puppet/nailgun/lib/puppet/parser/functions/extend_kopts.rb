module Puppet::Parser::Functions
  newfunction(:extend_kopts, :type => :rvalue, :doc => <<-EOS
This function are changing "kopts" parameter if user modifyed it
  EOS
  ) do |args|

      begin

        unless args.length == 2
          raise Puppet::ParseError, ("loadyaml(): wrong number of arguments (#{args.length}; must be 1)")
        end

        if File.exists?(args[0]) then
          metadata = YAML.load_file(args[0])
        else
          warning("Can't load " + args[0] + ". File does not exist!")
          nil
        end

        kopts = metadata["extend_kopts"]
        default_kopts = args[1].split(" ")
        new_kopts = kopts.split(" ")

        hash_default_kopts = {}
        hash_new_kopts = {}

        default_kopts.each do |e|
          key_value_d = e.split("=")
          hash_default_kopts[key_value_d[0]] = key_value_d[1]
        end

        new_kopts.each do |e|
          key_value_n = e.split("=")
          hash_new_kopts[key_value_n[0]] = key_value_n[1]
        end

        keys_intersection = hash_default_kopts.keys & hash_new_kopts.keys
        merged = hash_default_kopts.dup.update(hash_new_kopts)

        keys_intersection.each do |k|
          merged[k] = hash_new_kopts[k]
        end

        modify_kopts = merged.collect {|key, value| value ? "#{key}=#{value}" : "#{key}"}.join(' ')

      end
    return modify_kopts
  end
end
