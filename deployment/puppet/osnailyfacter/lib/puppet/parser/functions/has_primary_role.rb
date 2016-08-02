module Puppet::Parser::Functions
  newfunction(
      :has_primary_role,
      :type => :rvalue,
      :arity => 1,
      :doc => <<-EOS
Check if primary role is present.
EOS
  ) do |args|
    roles = args.first
    raise Puppet::ParseError, 'Argument must have array type!' unless roles.is_a? Array
    roles.any? { |r| r.start_with?('primary-') }
  end
end
