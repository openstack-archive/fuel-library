#
# Define: cinder::backend::iscsi
# Parameters:
#
# [*volume_backend_name*]
#   (optional) Allows for the volume_backend_name to be separate of $name.
#   Defaults to: $name
#
#
define cinder::backend::iscsi (
  $iscsi_ip_address,
  $volume_backend_name = $name,
  $volume_driver       = 'cinder.volume.drivers.lvm.LVMISCSIDriver',
  $volume_group        = 'cinder-volumes',
  $iscsi_helper        = $::cinder::params::iscsi_helper,
) {

  include cinder::params

  cinder_config {
    "${name}/volume_backend_name":  value => $volume_backend_name;
    "${name}/volume_driver":        value => $volume_driver;
    "${name}/iscsi_ip_address":     value => $iscsi_ip_address;
    "${name}/iscsi_helper":         value => $iscsi_helper;
    "${name}/volume_group":         value => $volume_group;
  }

  case $iscsi_helper {
    'tgtadm': {
      package { 'tgt':
        ensure => present,
        name   => $::cinder::params::tgt_package_name,
      }

      if($::osfamily == 'RedHat') {
        file_line { 'cinder include':
          path    => '/etc/tgt/targets.conf',
          line    => 'include /etc/cinder/volumes/*',
          match   => '#?include /',
          require => Package['tgt'],
          notify  => Service['tgtd'],
        }
      }

      service { 'tgtd':
        ensure  => running,
        name    => $::cinder::params::tgt_service_name,
        enable  => true,
        require => Class['cinder::volume'],
      }
    }

    'lioadm': {
      service { 'target':
        ensure  => running,
        enable  => true,
        require => Package['targetcli'],
      }

      package { 'targetcli':
        ensure => present,
        name   => $::cinder::params::lio_package_name,
      }
    }

    default: {
      fail("Unsupported iscsi helper: ${iscsi_helper}.")
    }
  }

}
