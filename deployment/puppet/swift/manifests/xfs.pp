#
# package dependencies for creating
# xfs partitions
class swift::xfs {
  if !defined(Package['xfsprogs']){
    package { 'xfsprogs':
      ensure => present
    }
  }
  if !defined(Package['parted']){
    package { 'parted':
      ensure => present
    }
  }
}
