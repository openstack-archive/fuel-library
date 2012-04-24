class nova::vncproxy() {

  # TODO make this work on Fedora

  # See http://nova.openstack.org/runnova/vncconsole.html for more details.

  package{ "noVNC":
    ensure  =>  purged,
  }
  file { '/etc/init.d/nova-novncproxy':
    ensure  =>  present,
    source  =>  'puppet:///modules/openstack/nova/nova-novncproxy.init',
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
    require => Package['git','nova-api'],
  }

  service { 'novncproxy':
    provider => upstart,
    require  => Vcsrepo['/var/lib/nova/noVNC']
  }

}
