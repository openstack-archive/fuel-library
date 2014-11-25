Puppet::Parser::Functions::newfunction(
    :defined_in_state,
    :type => :rvalue,
    :doc => 'Returns True when resource is defined in state.yaml file'
) do |args|

  yaml_file = '/var/lib/puppet/state/state.yaml'

  raise(Puppet::ParseError, "defined_in_state(): Wrong number of arguments " +
    "given (#{args.size} for 1)") if args.size != 1

  resource = args[0]

  begin
    yaml = YAML.load_file(yaml_file)
    if ! yaml["#{resource}"].nil?
      return true
    end
  rescue Exception => e
    Puppet.warning("#{e}")
  end

  return false
end
