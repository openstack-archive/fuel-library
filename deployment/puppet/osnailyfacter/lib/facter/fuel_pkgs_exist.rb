#FIXME(aglarendil): this fact is a temporary workaround
#FIXME: It should be removed after switching to
#FIXME: packages
require 'facter'
Facter.add('fuel_pkgs_exist') do
  setcode do
  rv = 'false'
  case Facter.value('osfamily')
    when /(?i)(debian)/
      pkg_grep_cmd = "apt-cache search"
    when /(?i)(redhat)/
      pkg_grep_cmd = "yum list | grep"
  end

  out1=Facter::Util::Resolution.exec("#{pkg_grep_cmd} fuel-ha-utils")
  out2=Facter::Util::Resolution.exec("#{pkg_grep_cmd} fuel-misc")
  if !out1.to_s.empty? and !out2.to_s.empty?
      rv = 'true'
  end
  rv
  end
end
