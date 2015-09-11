# Fact: l23_os
#
# Purpose: Return return os_name for using inside l23 network module
#
Facter.add(:l23_os) do
  setcode do
    case Facter.value(:operatingsystem)
      when /(?i)ubuntu/
        #todo: separate upstart and systemd based
        'ubuntu'
      when /(?i)centos/
        case Facter.value(:operatingsystemmajrelease)
          when /6/
            'centos6'
          when /7/
            'centos7'
        end
      when /(?i)redhat/
        case Facter.value(:operatingsystemmajrelease)
          when /7/
            'redhat7'
        end
      when /(?i)darwin/
        'osx'
    end
  end
end
