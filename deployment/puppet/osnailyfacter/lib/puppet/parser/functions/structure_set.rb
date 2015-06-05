module Puppet::Parser::Functions
  newfunction(:structure_set, :arity => -2, :doc => <<-eos
  Set a deep structure value
  eos
  ) do |args|

    path_set = lambda do |data, path, value|
      # no data
      break false unless data
      # wrong path
      break false unless path.is_a? Array
      # empty path
      break false unless path.any?
      # non-empty path and non-structure data -> return default
      break false unless data.is_a? Hash or data.is_a? Array

      key = path.shift
      if data.is_a? Array
        begin
          key = Integer key
        rescue ArgumentError
          break value
        end
      end

      if path.empty?
        data[key] = value
        break true
      end

      path_set.call data[key], path, value
    end

    data = args[0]
    path = args[1]
    value = args[2] || nil

    path = '' unless path
    path = path.split '/'
    path_set.call data, path, value
  end
end
