# Fact: l23_os
#
# Purpose: Return return os_name for using inside l23 network module
#
Facter.add(:l23_os) do
  setcode do
    osfamily = Facter.value(:osfamily)
    case osfamily
      when /(?i)darwin/
        return 'osx'
      when /(?i)debian/
        #todo: separate upstart and systemd based
        return 'ubuntu'
      when /(?i)redhat/
        #todo: separate centos6 and centos7
        return 'centos6'
    end
  end
end