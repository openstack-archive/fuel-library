# Fact: l23_os
#
# Purpose: Return return os_name for using inside l23 network module
#
Facter.add(:l23_os) do
  setcode do
    case Facter.value(:osfamily)
      when /(?i)darwin/
        'osx'
      when /(?i)debian/
        #todo: separate upstart and systemd based
        'ubuntu'
      when /(?i)redhat/
        #todo: separate centos6 and centos7
        'centos6'
    end
  end
end