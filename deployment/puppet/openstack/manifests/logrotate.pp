#
class openstack::logrotate (
    $role           = 'client',
    $rotation       = 'daily',
    $keep           = '7',
    $limitsize      = '300M',
) {
  validate_re($rotation, 'daily|weekly|monthly')

  if $role == 'server' {
  # configure logs rotation both for host OS and docker containers of rsylog server role
    # This file is used for daily/weekly/monthly log rotations
    file { "/etc/logrotate.d/10-fuel-docker.conf":
      owner => 'root',
      group => 'root',
      mode  => '0644',
      content => template("openstack/10-fuel-docker.conf.erb"),
    }
    # This file is used for hourly log rotations by (ana)cron
    file { "/etc/logrotate.d/20-fuel-docker.conf":
      owner => 'root',
      group => 'root',
      mode  => '0644',
      content => template("openstack/20-fuel-docker.conf.erb"),
    }

    $logrotatefile = '/etc/logrotate.d/20-fuel-docker.conf'
  } else {
  # configure logrotation for rsylog client role
    # This file is used for daily/weekly/monthly log rotations
    file { "/etc/logrotate.d/10-fuel.conf":
      owner => 'root',
      group => 'root',
      mode  => '0644',
      content => template("openstack/10-fuel.conf.erb"),
    }

    # This file is used for hourly log rotations by (ana)cron
    file { "/etc/logrotate.d/20-fuel.conf":
      owner => 'root',
      group => 'root',
      mode  => '0644',
      content => template("openstack/20-fuel.conf.erb"),
    }

    $logrotatefile = '/etc/logrotate.d/20-fuel.conf'
  }

# Configure (ana)cron for fuel custom hourly logrotations
  class { '::anacron': }
  case $osfamily {
    'RedHat': {
     # Due to bug existing, logrotate always returns 0. Use grep for detect errors:
     # would return 1 (considered as normal result), if logrotate returns no errors, return 0, if any.
     exec {'logrotate_check':
      path    => ["/usr/bin", "/usr/sbin", "/sbin", "/bin"],
      command => "logrotate $logrotatefile >& /tmp/logrotate && grep -q error /tmp/logrotate",
      returns => 1,
      require => File[$logrotatefile],
   }
  }
 }
}
