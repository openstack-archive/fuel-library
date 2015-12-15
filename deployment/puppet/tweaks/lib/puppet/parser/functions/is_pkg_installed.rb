module Puppet::Parser::Functions
  newfunction(:is_pkg_installed,
              :type => :rvalue,
              :arity => 1,
  ) do |args|
    osfamily = Facter.value(:osfamily)
    pkgname = args[0]

    case osfamily
    when 'Debian'
      command = "dpkg-query -l '#{pkgname}'"

    when 'RedHat'
      command = "rpm -q '#{pkgname}'"

    else
      raise Puppet::ParseError, 'is_pkg_installed(): unsupported operating system'
    end

    query = Puppet::Util::Execution.execute(command, {:failonfail => false})

    query.exitstatus == 0 ? true : false
  end
end
