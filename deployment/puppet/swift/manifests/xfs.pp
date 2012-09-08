#
# package dependencies for creating
# xfs partitions
class swift::xfs {
  package { ['xfsprogs', 'parted']:
    ensure => 'present'
  }
}
