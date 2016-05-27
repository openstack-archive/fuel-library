require 'facter/util/resolution'

Facter.add(:corosync_notifyd_installed) do
  setcode do
    ret = false
    case Facter.value('osfamily')
      when /(?i)(debian)/
        out = Facter::Util::Resolution.exec("dpkg-query -W -f='${Status}' corosync-notifyd 2>&1")
        if 'install ok installed' == out
          ret = true
        end
    end
    ret
  end
end
