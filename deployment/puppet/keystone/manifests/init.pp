#
# module for installing keystone
#
# does this always live on the nova API server?
#

class keystone(
  $package_ensure  = 'present',
  $log_verbose     = 'False',
  $log_debug       = 'False',
  $default_store   = 'sqlite',
  $bind_host       = '0.0.0.0',
  $bind_port       = '5000',
  $admin_bind_host = '0.0.0.0',
  $admin_bind_port = '5001'
) {

  # may need to add a user for HA

  # TODO does keystone need nova-common?

  #Package['keystone'] ~> Service<| 'title' = 'nova-api' |>

  # this package dependency needs to be removed when it
  # is added as a package dependency
  # I filed the following ticket against the packages: 909941
  if(! defined(Package['python-migrate'])) {
    package { 'python-migrate':
      ensure => present,
    }
  }

  package { 'keystone':
    ensure => $package_ensure,
    # I do not understand what this does??
    #notify => Exec["fix_tools_tracer"],
  }

  file { '/etc/keystone':
    ensure  => directory,
    owner   => 'keystone',
    group   => 'keystone',
    mode    => 0755,
    require => Package['keystone']
  }

  file { 'keystone.conf':
    path    => '/etc/keystone/keystone.conf',
    ensure  => present,
    owner   => 'keystone',
    mode    => 0600,
    content => template('keystone/keystone.conf.erb'),
    notify => Service['keystone'],
    require => Package['keystone'], #Exec['fix_tools_tracer']]
  }


#  # I would prefer not to be loading initial data into keystone
#  file { 'initial_data.sh':
#    path => '/var/lib/keystone/initial_data.sh',
#    ensure  => present,
#    owner   => 'keystone',
#    mode    => 0700,
#    content => template('keystone/initial_data.sh.erb'),
#    require => Package['keystone']
#  }
#
#  exec { 'create_keystone_data':
#    user => 'keystone',
#    command     => '/var/lib/keystone/initial_data.sh',
#    path        => [ '/bin', '/usr/bin' ],
#    unless      => 'keystone-manage user list | grep -q admin',
#    require     => [
#      Package['keystone'],
#      File['keystone.conf'],
#      File['initial_data.sh']
#    ]
#  }

  service { 'keystone':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  # TODO - figure out if I can remove this patching code?
  # this can't be serious
  # this Puppet code is patching keystone? Why?
  #exec { "fix_tools_tracer":
  #  command     => 'sed -e "s,^import tools.tracer,#import tools.tracer," -i /usr/lib/python2.6/dist-packages/keystone/middleware/auth_token.py /usr/bin/keystone',
  #  path        => [ "/bin", "/usr/bin" ],
  #  notify => [Service["nova-api"]],
  #  refreshonly => true,
  #  require     => [
  #    Package['keystone'],
  #  ]
  #}

}
