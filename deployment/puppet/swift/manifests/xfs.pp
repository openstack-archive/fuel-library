#
# package dependencies for creating
# xfs partitions
class swift::xfs {
  package { 'xfsprogs':
    ensure => 'present'
  }
  if !(defined(Package['parted'])) {
    package {"parted": ensure => 'present' } 
  }
}
