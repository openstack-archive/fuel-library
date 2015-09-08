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
        out.each_line do |line|
          version = line.scan(%r{\s+Candidate:\s+(.*)}).join() if line =~ %r{Candidate:}
          break unless version.nil?
        end
      when /(?i)(redhat)/
        pkg_grep_cmd = "yum info"
        out = Facter::Util::Resolution.exec("#{pkg_grep_cmd} libvirt 2>&1")
        out.each_line do |line|
          version = line.scan(%r{Version\s+:\s+(.*)\s+}).join() if line =~ %r{Version\s+:}
          break unless version.nil?
        end
    end
    version
  end
end
