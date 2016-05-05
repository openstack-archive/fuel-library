module Puppet::Parser::Functions
  newfunction(
      :resource_parameters,
      type: :rvalue,
      arity: -1,
      doc: <<-eof
Gather resource parameters and their values
  eof
  ) do |args|
    parameters = {}
    args.flatten.each_slice(2) do |key, value|
      if value.nil? and key.is_a? Hash
        parameters.merge! key
      else
        next if key.nil?
        next if value.nil?
        next if value == ''
        next if value == :undef
        key = key.to_s
        parameters.store key, value
      end
    end
    parameters
  end
end