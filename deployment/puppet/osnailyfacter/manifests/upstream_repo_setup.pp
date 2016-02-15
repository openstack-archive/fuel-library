# == Class: osnailyfacter::upstream_repo_setup
#
# Class which allows upstream OpenStack repositories
# to be configured, plus additional workarounds, such
# as APT pinning.
#
# == Parameters
#
# [*repo_type*]
#  A string containing upstream repository type.
#
# [*uca_repo_url*]
# A string containing the URL for Ubuntu Cloud Archive repository.
#
# [*debian_repo_url*]
# A string containing the URL for Debian backports repository.
#
# [*repo_priority*]
# A string containing the APT priority for the configured repo.
# Defaults to '9000'.
#
# [*os_release*]
# A string containing the repo name for the OpenStack release.
# Defaults to 'mitaka'.
#
# [*pin_haproxy*]
# Boolean for pinning HAProxy to use Fuel repository instead.
# Defaults to false.
#
# [*pin_rabbitmq*]
# Boolean for pinning RabbitMQ to use Fuel repository instead.
# Defaults to false.
#
# [*pin_ceph*]
# Boolean for pinning Ceph to use Fuel repository instead.
# Defaults to false.
#
# [*pin_priority*]
# A string containing the APT pin priority for all overridden packages.
# Defaults to 2000.
#
# [*ceph_packages*]
# Array of all ceph related packages. Used only when pin_ceph is true.
#
#

class osnailyfacter::upstream_repo_setup (
  $repo_type       = unset,
  $uca_repo_url    = unset,
  $debian_repo_url = unset,
  $repo_priority   = '9000',
  $os_release      = 'mitaka',
  $pin_haproxy     = false,
  $pin_rabbitmq    = false,
  $pin_ceph        = false,
  $pin_priority    = '2000',
  $ceph_packages   = ['ceph', 'ceph-common', 'libradosstriper1', 'python-ceph',
    'python-rbd', 'python-rados', 'python-cephfs', 'libcephfs1', 'librados2',
    'librbd1', 'radosgw', 'rbd-fuse']
) {

  if $repo_type == 'uca' {
    #FIXME(mattmyo): derive versions via fact or hiera
    apt::pin { 'haproxy-mos':
      packages => 'haproxy',
      version  => '1.5.3-*',
      priority => '2000',
    }

    apt::pin { 'ceph-mos':
      packages => $ceph_packages,
      version  => '0.94*',
      priority => '2000',
    }

    apt::pin { 'rabbitmq-server-mos':
      packages => 'rabbitmq-server',
      version  => '3.5.6-*',
      priority => '2000',
    }
  }

  case $repo_type {
    'fuel': {
      notice {'No repo changes needed for Fuel repo type.': }
    }
    'uca': {
      $release    = "${::lsbdistcodename}-updates/${os_release}"
      $repo_name  = 'UCA'
      $originator = 'Canonical'
      package { 'ubuntu-cloud-keyring':
        ensure  => 'present',
        require => apt::source[$repo_name],
      }
      $repo_url   = $uca_repo_url
    }
    'debian': {
      $release    = $os_release
      $repo_name  = 'debian_trusty'
      $originator = 'Debian'
      $repo_url   = $debian_repo_url
    }
    default: {
      fail("Invalid repo type ${repo_type}")
    }
  }

  if $repo_type != 'fuel' {
    apt::source { $repo_name:
      location => $repo_url,
      release  => $release,
      repos    => 'main'
    }

    apt::pin { $repo_name:
      packages   => '*',
      release    => $release,
      originator => $originator,
      codename   => "${release}/${os_release}",
      priority   => '9000',
    }
  }
}
