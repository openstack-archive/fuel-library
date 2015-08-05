Puppet::Parser::Functions::newfunction(:array_to_hash, :type => :rvalue, :doc => <<-EOS
converts array to hash with custom value
EOS
) do |argv|
  arr = argv[0]
  value = argv[1]

  return Hash[arr.collect { |v| [v, value] }]
end

