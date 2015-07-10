require 'facter/util/resolution'

Facter.add(:libvirt_package_version) do
  setcode do
    version=nil
    case Facter.value('osfamily')
      when /(?i)(debian)/
        pkg_grep_cmd = "apt-cache policy"
        out = Facter::Util::Resolution.exec("#{pkg_grep_cmd} libvirt-bin")
        version = out.split(/\n/).grep(/Candidate/i)[0].split(/\s+/)[2] if out
      when /(?i)(redhat)/
        pkg_grep_cmd = "yum info"
        out = Facter::Util::Resolution.exec("#{pkg_grep_cmd} libvirt")
        version = out.split(/\n/).grep(/Version/i)[0].split(/\s+/)[2] if out
    end
    version
  end
end
