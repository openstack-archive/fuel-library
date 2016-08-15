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
  $pin_erlang      = false,
  $pin_rabbitmq    = false,
  $pin_ceph        = false,
  $pin_xtrabackup  = false,
  $pin_mos_other   = false,
  $pin_priority    = '2000',
  $ceph_packages   = ['ceph', 'ceph-common', 'libradosstriper1', 'python-ceph',
    'python-rbd', 'python-rados', 'python-cephfs', 'libcephfs1', 'librados2',
    'librbd1', 'radosgw', 'rbd-fuse']
) {

  if $repo_type == 'uca' {

    #FIXME(mattmyo): derive versions via fact or hiera
    if $pin_haproxy {
      apt::pin { 'haproxy-mos':
        packages   => ['haproxy*', 'vim-haproxy'],
        originator => 'Mirantis',
        priority   => $pin_priority,
      }
    }
    if $pin_ceph {
      apt::pin { 'ceph-mos':
        packages   => $ceph_packages,
        originator => 'Mirantis',
        priority   => $pin_priority,
      }
    }
    if $pin_erlang {
      apt::pin { 'mos-erlang':
        packages   => 'erlang*',
        originator => 'Mirantis',
        priority   => $pin_priority,
      }
    }
    if $pin_rabbitmq {
      apt::pin { 'rabbitmq-server-mos':
        packages   => 'rabbitmq-server',
        originator => 'Mirantis',
        priority   => $pin_priority,
      }
    }
    if $pin_xtrabackup {
      apt::pin { 'mos-xtrabackup':
        packages   => ['percona-xtrabackup*', 'xtrabackup'],
        originator => 'Mirantis',
        priority   => $pin_priority,
      }
    }
    if $pin_mos_other {
      apt::pin { 'mos-other':
        packages   => ['fonts-materialdesignicons-webfont',
                       'libapache2-mod-wsgi*',
                       'libjs-*',
                       'live-boot*',
                       'nailgun-*',
                       'ruby-*'],
        originator => 'Mirantis',
        priority   => $pin_priority,
      }
    }

    apt::pin { 'openvswitch-mos':
      packages => 'openvswitch*',
      version  => '2.4.0*',
      priority => $pin_priority,
    }
    package { 'ubuntu-cloud-keyring':
      ensure  => 'present',
    }

  }
}
