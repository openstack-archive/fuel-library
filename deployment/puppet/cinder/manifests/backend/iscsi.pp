#
# Define: cinder::backend::iscsi
# Parameters:
#
# [*volume_backend_name*]
#   (optional) Allows for the volume_backend_name to be separate of $name.
#   Defaults to: $name
#
# [*volume_driver*]
#   (Optional) Driver to use for volume creation
#   Defaults to 'cinder.volume.drivers.lvm.LVMVolumeDriver'.
#
# [*volumes_dir*]
#   (Optional) Volume configuration file storage directory
#   Defaults to '/var/lib/cinder/volumes'.
#
# [*extra_options*]
#   (optional) Hash of extra options to pass to the backend stanza
#   Defaults to: {}
#   Example :
#     { 'iscsi_backend/param1' => { 'value' => value1 } }
#
define cinder::backend::iscsi (
  $iscsi_ip_address,
  $volume_backend_name = $name,
  $volume_driver       = 'cinder.volume.drivers.lvm.LVMVolumeDriver',
  $volume_group        = 'cinder-volumes',
  $volumes_dir         = '/var/lib/cinder/volumes',
  $iscsi_helper        = $::cinder::params::iscsi_helper,
  $iscsi_protocol      = 'iscsi',
  $extra_options       = {},
) {

  include ::cinder::params

  cinder_config {
    "${name}/volume_backend_name":  value => $volume_backend_name;
    "${name}/volume_driver":        value => $volume_driver;
    "${name}/iscsi_ip_address":     value => $iscsi_ip_address;
    "${name}/iscsi_helper":         value => $iscsi_helper;
    "${name}/volume_group":         value => $volume_group;
    "${name}/volumes_dir":          value => $volumes_dir;
    "${name}/iscsi_protocol":       value => $iscsi_protocol;
  }

  create_resources('cinder_config', $extra_options)

  case $iscsi_helper {
    'tgtadm': {
      package { 'tgt':
        ensure => present,
        name   => $::cinder::params::tgt_package_name,
      }

      if($::osfamily == 'RedHat') {
        file_line { 'cinder include':
          path    => '/etc/tgt/targets.conf',
          line    => "include ${volumes_dir}/*",
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
