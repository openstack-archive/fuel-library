module Puppet::Parser::Functions
  newfunction(:is_deb_installed,
              :type => :rvalue,
              :arity => 1,
  ) do |args|
    osfamily = Facter.value(:osfamily)

    raise Puppet::ParseError, "is_deb_installed(): Only Debian-based systems are supported" unless osfamily == 'Debian'
    raise Puppet::ParseError, "is_deb_installed(): Wrong number of arguments (#{args.size} given, 1 expected" unless args.size == 1

    pkgname = args[0]
    command = "dpkg-query -l '#{pkgname}'"
    query = Puppet::Util::Execution.execute(command)

    query.exitstatus == 0 ? 'true' : 'false'
  end
end
