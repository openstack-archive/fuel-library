#
# This fact returns the currently mounted ext{2,3,4}, xfs or btrfs disks as a
# comma seperate list.
#
require 'facter/util/resolution'

mounted_disks = []
case Facter.value(:kernel)
  when 'Linux'
    disk_cmd = 'egrep "(ext[2-4]|xfs|btrfs)" /etc/mtab | cut -d " " -f 2'
    disks = Facter::Util::Resolution.exec(disk_cmd)
    mounted_disks = disks.split()
end

Facter.add(:mounted_disks) do
  setcode do
     mounted_disks.join(",")
  end
end

