#
# Installs keystone from source. This is not yet fully implemented
#
# == Dependencies
# == Examples
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2012 Puppetlabs Inc, unless otherwise noted.
#
class keystone::dev::install(
  $source_dir = '/usr/local/keystone'
) {
  # make sure that I have python 2.7 installed

  Class['openstack::dev'] -> Class['keystone::dev::install']

  # there are likely conficts with other packages
  # introduced by these resources
  package { [
      'python-dev',
      'libxml2-dev',
      'libxslt1-dev',
      'libsasl2-dev',
      'libsqlite3-dev',
      'libssl-dev',
      'libldap2-dev',
      'sqlite3'
    ]:
      ensure => latest,
  }

  vcsrepo { $source_dir:
    ensure   => present,
    provider => git,
    source   => 'git://github.com/openstack/keystone.git',
  }

  Exec {
    cwd         => $source_dir,
    path        => '/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo[$source_dir],
    logoutput   => true,
    # I have disabled timeout since this seems to take forever
    # this may be a bad idea :)
    timeout     => 0,
  }

  # TODO - really, I need a way to take this file and
  # convert it into package resources
  exec { 'install_dev_deps':
    command => 'pip install -r tools/pip-requires',
  }

  exec { 'install_keystone_source':
    command => 'python setup.py develop',
    require => Exec['install_dev_deps'],
  }

}
