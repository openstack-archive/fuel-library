class osnailyfacter::logging::logging {

  notice('MODULAR: logging/logging.pp')

  $base_syslog_hash   = hiera('base_syslog')
  $syslog_hash        = hiera('syslog')
  $use_syslog         = hiera('use_syslog', true)
  $debug              = pick($syslog_hash['debug'], hiera('debug', false))
  $rabbit_fqdn_prefix = hiera('node_name_prefix_for_messaging', 'messaging-')
  ##################################################

  $base_syslog_rserver  = {
    'remote_type' => pick($base_syslog_hash['syslog_transport'], 'tcp'),
    'server'      => $base_syslog_hash['syslog_server'],
    'port'        => $base_syslog_hash['syslog_port']
  }

  $syslog_rserver = {
    'remote_type' => $syslog_hash['syslog_transport'],
    'server'      => $syslog_hash['syslog_server'],
    'port'        => $syslog_hash['syslog_port'],
  }

  if $syslog_hash['metadata']['enabled'] {
    $rservers = [$base_syslog_rserver, $syslog_rserver]
  } else {
    $rservers = [$base_syslog_rserver]
  }

  if $use_syslog {
    if ($::operatingsystem == 'Ubuntu') {
      # ensure the var log folder permissions are correct even if it's a mount
      # LP#1489347
      file { '/var/log':
        owner => 'root',
        group => 'syslog',
        mode  => '0775',
      }
    }

    if roles_include(['ironic']) {
      $ironic_collector = true
    }

    class { '::openstack::logging':
      role               => 'client',
      show_timezone      => true,
      # log both locally include auth, and remote
      log_remote         => true,
      log_local          => true,
      log_auth_local     => true,
      # keep four weekly log rotations,
      # force rotate if 300M size have exceeded
      rotation           => 'weekly',
      keep               => '4',
      minsize            => '10M',
      maxsize            => '100M',
      # remote servers to send logs to
      rservers           => $rservers,
      # should be true, if client is running at virtual node
      virtual            => str2bool($::is_virtual),
      rabbit_fqdn_prefix => $rabbit_fqdn_prefix,
      # Rabbit doesn't support syslog directly
      rabbit_log_level   => 'NOTICE',
      debug              => $debug,
      ironic_collector   => $ironic_collector,
    }

  }

}
