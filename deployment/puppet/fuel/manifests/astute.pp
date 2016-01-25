class fuel::astute(
  $rabbitmq_host            = $::fuel::params::rabbitmq_host,
  $rabbitmq_astute_user     = $::fuel::params::rabbitmq_astute_user,
  $rabbitmq_astute_password = $::fuel::params::rabbitmq_astute_password,
  $bootstrap_flavor         = 'centos',
  ) inherits fuel::params {

  $bootstrap_profile = $bootstrap_flavor ? {
    /(?i)centos/                 => 'bootstrap',
    /(?i)ubuntu/                 => 'ubuntu_bootstrap',
    default                      => 'bootstrap',
  }

  $packages = [
    "psmisc",
    "python-editor",
    "nailgun-mcagents",
    "sysstat",
    "rubygem-amqp",
    "rubygem-amq-protocol",
    "rubygem-i18n",
    "rubygem-tzinfo",
    "rubygem-minitest",
    "rubygem-symboltable",
    "rubygem-thread_safe",
  ]

  ensure_packages($packages)

  case $::operatingsystem {
    /(?i)(centos|redhat)/: {
      case $::operatingsystemrelease {
        /7.+/: {
          package { 'rubygem-astute':
            require => Package[$packages]
          }
        }
      }
    }
  }

  file { '/etc/sysconfig/astute':
    content => template('fuel/astute/sysconfig.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644'
  }

  file { '/usr/bin/astuted':
    content => template('fuel/astute/astuted.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => 0755,
  }

  file {"/etc/astute":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => 0755,
  }

  file {"/etc/astute/astuted.conf":
    content => template("fuel/astute/astuted.conf.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    require => File["/etc/astute"],
  }

  file {"/var/log/astute":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => 0755,
  }

  exec {'use correct versions of rubygem packages':
    command => '/usr/bin/sed -i "/amq-protocol/ s/~>/>=/" /usr/share/gems/specifications/amqp-*.gemspec',
    require => Package[$packages],
  } ->

  fuel::systemd { ['astute']:
    require => Class['fuel::astute']
  }

}
