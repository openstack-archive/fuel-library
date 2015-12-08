# == Class: nailgun::systemd
#
# Apply local settings for nailgun services.
#
# At this moment only start/stop timeouts
# and syslog identificators.
#
# === Parameters
#
# [*services*]
#   (required) Array or String. This is an array of service names (or just service name as tring)
#   for which local changes will be applied.
#
# [*production*]
#   (required) String. Determine environment.
#   Changes applies only for 'prod' and 'docker' environments.
#

class nailgun::systemd (
  $services,
  $production,
  $real_exec = {
    'ostf' => '/usr/bin/ostf-server',
    'oswl_flavor_collectord' => '/usr/bin/oswl_collectord flavor',
    'oswl_image_collectord' => '/usr/bin/oswl_collectord image',
    'oswl_keystone_user_collectord' => '/usr/bin/oswl_collectord keystone_user',
    'oswl_tenant_collectord' => '/usr/bin/oswl_collectord tenant',
    'oswl_vm_collectord' => '/usr/bin/oswl_collectord vm',
    'oswl_volume_collectord' => '/usr/bin/oswl_collectord volume',
    'nailgun' => '/usr/sbin/uwsgi -y /etc/nailgun/uwsgi_nailgun.yaml',
    'astute' => '/usr/bin/astuted --config /etc/astute/astuted.conf --logfile /var/log/astute/astute.log --loglevel info --workers 7'
  }
) {

  case $production {
    'prod', 'docker': {
      if !empty($services) {
        nailgun::systemd::config { $services: real_exec => $real_exec }
      }
    }
    default: { }
  }

}
