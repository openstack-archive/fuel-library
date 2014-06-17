# Class: selinux::package
#
# This module manages additional packages required to support some of the functions.
#
# Parameters:
#
# There are no default parameters for this class.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# This class file is not called directly
class selinux::package {
  case $::operatingsystem {
    CentOS,Fedora,RHEL,RedHat,Scientific: {
      case $::operatingsystemrelease {
        /^5.+$/: {
          package { 'policycoreutils':
            ensure => present,
          }
        }
        /^6.+$/: {
          package { 'policycoreutils-python':
            ensure => present,
          }
        }
        default: {
          # We only deal with CentOS 5 or 6
        }
      }
    }
    default: {
      # Nothing to do, only manage SELinux on OS's defined above
    }
  }
}
