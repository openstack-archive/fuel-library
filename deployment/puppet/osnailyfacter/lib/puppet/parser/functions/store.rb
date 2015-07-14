module Puppet::Parser::Functions
  newfunction(
      :store,
      :arity => -3,
      :doc => <<-eos
Set a deep structure value inside a hash or an array.

$data = {
  'a' => {
    'b' => [
      'b1',
      'b2',
      'b3',
    ]
  }
}

store($data, 'a/b/2', 'new_value', '/')

=> $data = {
  'a' => {
    'b' => [
      'b1',
      'b2',
      'new_value',
    ]
  }
}

a -> first hash key
b -> second hash key
2 -> array index starting with 0

new_valuw -> new value to be assigned
/ -> (optional) path delimiter. Defaults to '/'

  eos
  ) do |args|

    path_set = lambda do |data, path, value|
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
          break false
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
    value = args[2]
    separator = args[3]
    separator = '/' unless separator

    path = '' unless path
    path = path.split separator
    success = path_set.call data, path, value
    fail "Could not set value for: #{args[0].inspect} at: '#{args[1]}' to: #{args[2].inspect}!" unless success
    success
  end
end
