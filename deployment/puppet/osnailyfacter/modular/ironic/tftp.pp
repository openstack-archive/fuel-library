notice('MODULAR: ironic/tftp.pp')

$network_scheme = hiera('network_scheme', {})
prepare_network_config($network_scheme)
$tftp_server = get_network_role_property ('baremetal', 'ipaddr')
$tftp_root = '/tftpboot/'
$images_path = '/var/lib/ironic/images/'
$tftp_master_path = '/tftpboot/master_images'
$instance_master_path = '/var/lib/ironic/master_images'

  ::xinetd::service {'tftp':
    port   => '69',
    server => '/usr/sbin/in.tftpd',
    server_args => '-s $base',
    socket_type => 'dgram',
    protocol    => 'udp',
    user => $admin_user,
  }

notify {"$network_scheme":}
notify {"$tftp_server":}

class { '::ironic::drivers::pxe':
  tftp_server          => $tftp_server,
  tftp_root            => $tftp_root,
  images_path          => $images_path,
  tftp_master_path     => $tftp_master_path,
  instance_master_path => $instance_master_path,

}

