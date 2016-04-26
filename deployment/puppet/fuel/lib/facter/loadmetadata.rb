module Puppet::Parser::Functions

  newfunction(:loadmetadata, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
    Load a YAML file containing a metadata hash, and return it.
    Return an empty hash if YAML file does not exist.

    For example:
        $bootstrap_meta = loadmetadata("/var/www/nailgun/bootstraps/active_bootstrap/metadata.yaml")
    ENDHEREDOC

    unless args.length == 1
      raise Puppet::ParseError, ("loadmetadata(): wrong number of arguments (#{args.length}; must be 1)")
    end

    if File.exists?(args[0]) then
      YAML.load_file(args[0])
    else
      {}
    end

  end

end
