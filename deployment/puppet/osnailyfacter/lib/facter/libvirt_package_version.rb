require 'facter'
Facter.add('libvirt_package_version') do
  setcode do
  case Facter.value('osfamily')
    when /(?i)(debian)/
      pkg_grep_cmd = "apt-cache policy"
      out = Facter::Util::Resolution.exec("#{pkg_grep_cmd} libvirt-bin")
      version = out.grep('Candidate').split(/\s+/)[2]
    when /(?i)(redhat)/
      pkg_grep_cmd = "yum info"
      out = Facter::Util::Resolution.exec("#{pkg_grep_cmd} libvirt-bin")
      version = out.grep('Version').split(/\s+/)[3]
  end

  if !version
    fail "libvirt-bin package was not found"
  end
  version
  end
end
