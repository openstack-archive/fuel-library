# Make periodic cron jobs run in the idle scheduling class to reduce
# their impact on other system activities.
# Make anacron being manage 20-fuel logrotate job in /etc/cron.hourly
# for RHEL/CENTOS, and same by cron (it does by default) for DEBIAN/UBUNTU
class anacron::config {

  File {
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  case $::osfamily {
    'RedHat': {
      # assume cronie-anacron is installed

      file { '/etc/anacrontab':
        source => 'puppet:///modules/anacron/anacrontab',
      }

      file { '/etc/cron.hourly/':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
      }

      file { '/etc/cron.d/':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
      }

      file { '/etc/cron.d/0hourly':
        source => 'puppet:///modules/anacron/0hourly',
      }

      file { '/etc/cron.d/fuel-logrotate':
        mode   => '0755',
        source => 'puppet:///modules/anacron/logrotate',
      }

      file { '/etc/cron.hourly/0anacron':
        mode   => '0755',
        source => 'puppet:///modules/anacron/0anacron-hourly',
      }
    }
    'Debian': {
      # assume anacron is installed

      file { '/etc/anacrontab':
        source => 'puppet:///modules/anacron/anacrontab-ubuntu',
      }

      file { '/etc/cron.d/anacron':
        source => 'puppet:///modules/anacron/anacron-ubuntu',
      }

      file { '/etc/cron.d/fuel-logrotate':
        mode   => '0755',
        source => 'puppet:///modules/anacron/logrotate-ubuntu',
      }
    }
    default: {
      fail("Unsupported platform: ${::osfamily}/${::operatingsystem}")
    }
  }

  if $::anacron::debug {
    file { '/etc/cron.d/logrotate-debug':
      source => 'puppet:///modules/anacron/logrotate-debug'
    }
  }

  cron { 'fuel-logrotate':
    command => '/etc/cron.d/fuel-logrotate',
    user    => 'root',
    minute  => '*/15',
  }

  File<| tag == 'anacron::config' |> -> Cron['fuel-logrotate']
}
