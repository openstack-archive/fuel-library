# Class: rsync::server
#
# The rsync server. Supports both standard rsync as well as rsync over ssh
#
# Requires:
#   class xinetd if use_xinetd is set to true
#   class rsync
#
class rsync::server(
  $use_xinetd = true,
  $address    = '0.0.0.0',
  $motd_file  = 'UNSET',
  $use_chroot = 'yes',
  $uid        = 'nobody',
  $gid        = 'nobody'
) inherits rsync {

  $conf_file = $::osfamily ? {
    'Debian' => '/etc/rsyncd.conf',
    default  => '/etc/rsync.conf',
  }

  $rsync_fragments = '/etc/rsync.d'

  if $use_xinetd {
    include xinetd
    xinetd::service { 'rsync':
      bind        => $address,
      port        => '873',
      cps         => '512 10',
      per_source  => 'UNLIMITED',
      flags       => 'IPv4',
      server      => '/usr/bin/rsync',
      server_args => "--daemon --config ${conf_file}",
      require     => Package['rsync'],
    }
  } else {
    service { 'rsync':
      ensure     => running,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
      subscribe  => Exec['compile fragments'],
    }

    if ( $::osfamily == 'Debian' ) {
      file { '/etc/default/rsync':
        source => 'puppet:///modules/rsync/defaults',
        notify => Service['rsync'],
      }
    }
  }

  if $motd_file != 'UNSET' {
    file { '/etc/rsync-motd':
      source => 'puppet:///modules/rsync/motd',
    }
  }

  file { $rsync_fragments:
    ensure  => directory,
  }

  # Template uses:
  # - $use_chroot
  # - $address
  # - $motd_file
  file { "${rsync_fragments}/header":
    content => template('rsync/header.erb'),
  }

  file { $conf_file:
    ensure => present,
  } ~> Exec['compile fragments']

  # perhaps this should be a script
  # this allows you to only have a header and no fragments, which happens
  # by default if you have an rsync::server but not an rsync::repo on a host
  # which happens with cobbler systems by default
  exec { 'compile fragments':
    refreshonly => true,
    command     => "ls ${rsync_fragments}/frag-* 1>/dev/null 2>/dev/null && if [ $? -eq 0 ]; then cat ${rsync_fragments}/header ${rsync_fragments}/frag-* > ${conf_file}; else cat ${rsync_fragments}/header > ${conf_file}; fi; $(exit 0)",
    subscribe   => File["${rsync_fragments}/header"],
    path        => '/bin:/usr/bin:/usr/local/bin',
  }
}
