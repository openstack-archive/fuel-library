# == Class: osnailyfacter::package_pins
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

class osnailyfacter::package_pins (
  $repo_type       = unset,
  $pin_haproxy     = false,
  $pin_rabbitmq    = false,
  $pin_ceph        = false,
  $pin_priority    = '2000',
  $ceph_packages   = ['ceph', 'ceph-common', 'libradosstriper1', 'python-ceph',
    'python-rbd', 'python-rados', 'python-cephfs', 'libcephfs1', 'librados2',
    'librbd1', 'radosgw', 'rbd-fuse']
) {

  if $repo_type == 'uca' {
    # versions of pins depending on ubuntu release
    if $::operatingsystemrelease =~ /^14/ {
      $ceph_version        = '0.94*'
      $rabbitmq_version    = '3.6*'
      $openvswitch_version = '2.4.0*'
    } else {
      # TODO(aschultz): currently there is no MOS ceph version for newton
      $ceph_version        = undef
      $rabbitmq_version    = '3.6*'
      # NOTE(aschultz): currently there is no MOS version of openvswitch-*
      $openvswitch_version = undef

      # NOTE(aschultz): LP#1612556
      # make sure MOS python items are less than the Ubuntu provided packages
      apt::pin { 'mos-python':
        packages   => 'python-*',
        originator => 'Mirantis',
        priority   => '499'
      }
    }

    #FIXME(mattmyo): derive versions via fact or hiera
    if $pin_haproxy {
      # TODO(aschultz): xenial has the same version so switch to the originator
      apt::pin { 'haproxy-mos':
        packages   => 'haproxy',
        originator => 'Mirantis',
        priority   => $pin_priority,
      }
    }
    if $pin_ceph and $ceph_version {
      apt::pin { 'ceph-mos':
        packages => $ceph_packages,
        version  => $ceph_version,
        priority => $pin_priority,
      }
    }
    if $pin_rabbitmq and $rabbitmq_version{
      apt::pin { 'rabbitmq-server-mos':
        packages => 'rabbitmq-server',
        version  => $rabbitmq_version,
        priority => $pin_priority,
      }
    }
    if $openvswitch_version {
      apt::pin { 'openvswitch-mos':
        packages => 'openvswitch*',
        version  => $openvswitch_version,
        priority => $pin_priority,
      }
    }

    package { 'ubuntu-cloud-keyring':
      ensure  => 'present',
    }
  }
}
