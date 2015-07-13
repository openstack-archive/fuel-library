#
# package dependencies for creating
# xfs partitions
class swift::xfs {

  $packages = ['xfsprogs', 'parted']
  ensure_packages($packages)

}
