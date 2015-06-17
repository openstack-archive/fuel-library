module Puppet::Parser::Functions
newfunction(:package_version, :type => :rvalue, :doc => <<-EOS
  Return package version which is going to be installed from mirrors
  Argument1: 'package_name'
  Argument2: 'osfamily'
  EOS
  ) do |args|
    package_name = args[0]
    osfamily = args[1]
    if osfamily == 'Redhat'
      version = `yum info #{package_name} | grep Version | awk '{print $3}'`
    elsif osfamily == 'Debian'
      version = `apt-cache policy #{package_name} | grep Candidate | awk '{print $2}'`
    else
      fail 'Unsupported operating system'
    end
    if !version
      fail "Package was not found"
    end
    return version
  end

end
