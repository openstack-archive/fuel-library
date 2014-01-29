class ironic::source inherits ironic::params {
  $sourcedir = $::ironic::params::source
  $venvdir = $::ironic::params::venv
  $cachedir = $::ironic::params::cache_dir

  # get ironic and ironic client sources
  exec {"ironic_source":
    command => "git clone https://github.com/openstack/ironic.git",
    cwd => $sourcedir,
    unless => "test -e ${sourcedir}/ironic",
  } ->

  exec {"ironic_client_source":
    command => "git clone https://github.com/openstack/python-ironicclient.git",
    cwd => $sourcedir,
    unless => "test -e ${sourcedir}/python-ironicclient",
  } ->

  # create virtualenv
  exec {"ironic_virtualenv":
    command => "virtualenv ${venvdir}",
    unless => "test -e ${venvdir}",
  } ->

  exec { 'ironic_psycopg2':
    command => "${venvdir}/bin/pip install psycopg2"
  } ->

  exec { 'ironic_pbr':
    command => "${venvdir}/bin/pip install pbr"
  } ->

  # install ironic and ironic client
  exec {"ironic_install":
    command => "${venvdir}/bin/python setup.py install",
    cwd => "${sourcedir}/ironic",
    timeout => 600,
  } ->

  exec {"ironic_client_install":
    command => "${venvdir}/bin/python setup.py install",
    cwd => "${sourcedir}/python-ironicclient",
  } ->

  file {"/etc/ironic":
    ensure => directory,
  } ->

  exec {"ironic_config_sample":
    command => "cp ${sourcedir}/ironic/etc/ironic/ironic.conf.sample /etc/ironic/ironic.conf",
  } ->

  ironic_config {
    'DEFAULT/debug': value => 'True';
    'DEFAULT/log_file': ensure => absent;
    'DEFAULT/use_syslog': value => 'True';
  } ->


  group {"ironic":
    system => true,
    ensure => present,
  } ->

  user {"ironic":
    ensure => present,
    gid => "ironic",
    require => Group["ironic"],
  } ->

  file {"/var/run/ironic":
    ensure => directory,
    owner => "ironic"
  } ->

  file {"/var/log/ironic":
    ensure => directory,
    owner => "ironic"
  } ->

  exec { 'ironic_cache':
    command => "mkdir -p ${cachedir}/api; chown ironic ${cachedir}/api; mkdir -p ${cachedir}/registry; chown ironic ${cachedir}/registry;"
  } ->

  file {"/etc/init.d/ironic-api":
    content => template('ironic/ironic-api.erb'),
    mode => 0755,
  } ->

  file {"/etc/init.d/ironic-conductor":
    content => template('ironic/ironic-conductor.erb'),
    mode => 0755,
  }
}
