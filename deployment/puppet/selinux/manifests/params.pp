# Class: selinux::params
#
# Description
#  This class provides default parameters for the selinux class
#
# Sample Usage:
#  mod_dir = $selinux::params::sx_mod_dir
#
class selinux::params {
  $sx_mod_dir   = '/usr/share/selinux'
  $mode         = 'disabled'
}
