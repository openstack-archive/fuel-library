# == Class: fuel::astute
#
# === Parameters
#
# [*debug*]
#  (Optional) Boolean used to enable debug logging
#  Defaults to $::fuel::params::debug
#
# [*rabbitmq_host*]
# [*rabbitmq_astute_user*]
# [*rabbitmq_astute_password*]
# [*bootstrap_profile*]
#
class fuel::astute(
  $debug                    = $::fuel::params::debug,
  $rabbitmq_host            = $::fuel::params::rabbitmq_host,
  $rabbitmq_astute_user     = $::fuel::params::rabbitmq_astute_user,
  $rabbitmq_astute_password = $::fuel::params::rabbitmq_astute_password,
  $bootstrap_profile        = $::fuel::params::bootstrap_profile,
) inherits fuel::params {

  $log_level = $debug ? {
    true    => 'debug',
    default => 'info',
  }

  $packages = [
    'psmisc',
    'python-editor',
    'nailgun-mcagents',
    'sysstat',
    'rubygem-amqp',
    'rubygem-amq-protocol',
    'rubygem-i18n',
    'rubygem-tzinfo',
    'rubygem-minitest',
    'rubygem-symboltable',
    'rubygem-thread_safe',
  ]

  ensure_packages($packages)

  case $::operatingsystem {
    /(?i)(centos|redhat)/: {
      case $::operatingsystemrelease {
        /7.+/: {
          ensure_packages(['rubygem-astute'])
          Package[$packages] -> Package['rubygem-astute']
        }
      }
    }
  }

  file { '/etc/sysconfig/astute':
    content => template('fuel/astute/sysconfig.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644'
  } ~> Service <| title == 'astute' |>

  file { '/usr/bin/astuted':
    content => template('fuel/astute/astuted.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  } ~> Service <| title == 'astute' |>

  file {'/etc/astute':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file {'/etc/astute/astuted.conf':
    content => template('fuel/astute/astuted.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/astute'],
  } ~> Service <| title == 'astute' |>

  file {'/var/log/astute':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # FIXME(dteselkin): use correct versions of rubygem packages
  exec {'use correct versions of rubygem packages':
    command => '/usr/bin/sed -i "/amq-protocol/ s/~>/>=/" /usr/share/gems/specifications/amqp-*.gemspec',
    require => Package[$packages],
  }

}
