# Facter is to check Libvirt package version on Ubuntu and CentOS systems.
# It's required for checking group name which is created by libvirt package.
# If libvirt version on Ubuntu is 1.2.9 or more group name is 'libvirt';
# if version is less than 1.2.9, group name should be default (libvirtd for Ubuntu).

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
        out = Facter::Util::Resolution.exec("#{pkg_grep_cmd} libvirt 2>&1")
        yum_out = out.split(/\n/).grep(/Version/i)
        version = yum_out[0].split(/\s+/)[2] unless yum_out.empty?
    end
    version
  end
end
