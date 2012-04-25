class nova::vncproxy(
  $enabled   = false,
  $host      = '0.0.0.0',
  $port      = '6080',
) {

  include nova::params

  # TODO make this work on Fedora

  # See http://nova.openstack.org/runnova/vncconsole.html for more details.

  nova_config {
    'novncproxy_host': value => $host;
    'novncproxy_port': value => $port;
  }

  package { 'python-numpy':
    name   => $::nova::params::numpy_package_name,
    ensure => present,
  }

  nova::generic_service { 'vncproxy':
    enabled      => $enabled,
    package_name => $::nova::params::vncproxy_package_name,
    service_name => $::nova::params::vncproxy_service_name,
    require      => Package['python-numpy']
  }

  if ($::osfamily == 'Debian' and $::operatingsystem != 'Debian') {

    require git

    package{ "noVNC":
      ensure  =>  purged,
    }
    file { '/etc/init.d/nova-novncproxy':
      ensure  =>  present,
      source  =>  'puppet:///modules/nova/nova-novncproxy.init',
      mode    =>  0750,
    }
    # this temporary upstart script needs to be removed
    file { '/etc/init/nova-novncproxy.conf':
      ensure  =>  present,
      content =>
  '
  description "nova noVNC Proxy server"
  author "Etienne Pelletier <epelletier@morphlabs.com>"

  start on (local-filesystems and net-device-up IFACE!=lo)
  stop on runlevel [016]

  respawn

  exec su -s /bin/bash -c "exec /var/lib/nova/noVNC/utils/nova-novncproxy --flagfile=/etc/nova/nova.conf --web=/var/lib/nova/noVNC" nova
  ',
     mode    =>  0750,
    }

    # TODO this is terrifying, it is grabbing master
    # I should at least check out a branch
    vcsrepo { '/var/lib/nova/noVNC':
      ensure   => latest,
      provider => git,
      source   => 'https://github.com/cloudbuilders/noVNC.git',
      revision => 'HEAD',
      require  => Package['nova-api'],
      before   => Nova::Generic_service['vncproxy'],
    }
  }

}
