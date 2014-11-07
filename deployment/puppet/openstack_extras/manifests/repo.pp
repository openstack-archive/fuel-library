#
# Sets up the package repos necessary to use OpenStack
# on RHEL-alikes and Ubuntu
#
# === parameters
#
# [*release*]
#   The OpenStack release name. Options are 'icehouse', 'havana',
#   'grizzly', or 'folsom'.
#   Defaults to 'icehouse'.
#
class openstack_extras::repo(
  $release = 'icehouse'
) {
  case $release {
    'icehouse', 'havana', 'grizzly': {
      if $::osfamily == 'RedHat' {
        class {'openstack_extras::repo::rdo': release => $release }
      } elsif $::operatingsystem == 'Ubuntu' {
        class {'openstack_extras::repo::uca': release => $release }
      }
    }
    'folsom': {
      if $::osfamily == 'RedHat' {
        include ::epel
      } elsif $::operatingsystem == 'Ubuntu' {
        class {'openstack_extras::repo::uca': release => $release }
      }
    }
    default: {
      notify { "WARNING: openstack_repo::repo parameter 'release' of '${release}' not recognized; please use one of 'icehouse', 'havana', 'grizzly' or 'folsom'.": }
    }
  }
}
