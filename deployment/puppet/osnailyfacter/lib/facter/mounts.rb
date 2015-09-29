#
# This fact returns the currently mounted ext{2,3,4}, xfs or btrfs disks as an
# array
#

mounts = []
case Facter.value(:kernel)
  when 'Linux'
    include_filesystems = ['ext[2-4]', 'xfs', 'btrfs']
    filesystems_re = Regexp.new(include_filesystems.join('|'))
    File.open('/proc/mounts').each do |line|
      mount = line.split(' ')[1] if filesystems_re.match(line)
      # if for some reason the mount line is not properly formated, this
      # prevents nil from being added to the mounts. For example a line that
      # only has 'xfs' would return nil
      mounts << mount unless mount.nil?
    end
end

Facter.add(:mounts) do
  setcode do
     mounts
  end
end

