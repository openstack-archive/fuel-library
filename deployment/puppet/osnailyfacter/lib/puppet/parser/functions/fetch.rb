module Puppet::Parser::Functions
  newfunction(:fetch, :type => :rvalue, :arity => -2, :doc => <<-eos
Looks up into a compex structure of arrays and hashes and returns a value
or the default value if nothing was found.

Key can contain slashes to describe path components. The fuction will go down
the structure and try to extract the required value.

$data = {
  'a' => {
    'b' => [
      'b1',
      'b2',
      'b3',
    ]
  }
}

$value = structure('a/b/2', 'not_found')
=> $value = 'b3'

a -> first hash key
b -> second hash key
2 -> array index starting with 0
not_found -> will be returned if there is no value or the path did not match

In addition to the required "key" argument, "structure" accepts default
argument. It will be returned if no value was found or a path component is
missing. And the fourth argument can set a variable path separator.
  eos
  ) do |args|

    path_lookup = lambda do |data, path, default|
      # no data -> return default
      break default if data.nil?
      # wrong path -> return default
      break default unless path.is_a? Array
      # empty path -> value found
      break data unless path.any?
      # non-empty path and non-structure data -> return default
      break default unless data.is_a? Hash or data.is_a? Array

      key = path.shift
      if data.is_a? Array
        begin
          key = Integer key
        rescue ArgumentError
          break default
        end
      end
      path_lookup.call data[key], path, default
    end

    data = args[0]
    path = args[1]
    default = args[2]
    separator = args[3]
    separator = '/' unless separator

    path = '' unless path
    path = path.split separator
    path_lookup.call data, path, default
  end
end
