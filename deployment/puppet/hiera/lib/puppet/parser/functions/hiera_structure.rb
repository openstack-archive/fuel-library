require 'hiera_puppet'

module Puppet::Parser::Functions
  newfunction(:hiera_structure, :type => :rvalue, :arity => -2, :doc => "Performs a
  standard priority lookup and returns the most specific value for a given key.
  The returned value can be data of any type (strings, arrays, or hashes).

  Key can contain slashes to describe path components. The fuction will go down
  the structure and try to extract the required value.

  $data = {
    'a' => {
      'b' => [
        'b1',
        'b2',
        'b3'
      ]
    }
  }

  $value = hiera_structure('a/b/1')
  => $value = 'b2'

  In addition to the required `key` argument, `hiera` accepts two additional
  arguments:

  - a `default` argument in the second position, providing a value to be
    returned in the absence of matches to the `key` argument
  - an `override` argument in the third position, providing a data source
    to consult for matching values, even if it would not ordinarily be
    part of the matched hierarchy. If Hiera doesn't find a matching key
    in the named override data source, it will continue to search through the
    rest of the hierarchy.

  More thorough examples of `hiera` are available at:
  <http://docs.puppetlabs.com/hiera/1/puppet.html#hiera-lookup-functions>
  ") do |*args|

    path_lookup = lambda do |data, path, default|
      break default unless data
      break data unless path.is_a? Array and path.any?
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

    key, default, override = HieraPuppet.parse_args(args)
    path = key.split '/'
    key = path.shift
    data = HieraPuppet.lookup(key, nil, self, override, :priority)
    path_lookup.call data, path, default
  end
end
