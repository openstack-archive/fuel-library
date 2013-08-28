class ceph::glance (
  $default_store,
  $rbd_store_user,
  $rbd_store_pool,
  $show_image_direct_url,
) {
  if str2bool($::glance_api_conf) {
    package {['python-ceph']:
      ensure  => latest,
    }
    exec {'Copy config':
      command => "scp -r ${mon_nodes[-1]}:/etc/ceph/* /etc/ceph/",
      require => Package['ceph'],
      returns => 0,
    }
    glance_api_config {
      'DEFAULT/default_store':           value => $default_store;
      'DEFAULT/rbd_store_user':          value => $rbd_store_user;
      'DEFAULT/rbd_store_pool':          value => $rbd_store_pool;
      'DEFAULT/show_image_direct_url':   value => $show_image_direct_url;
    }~>
    service { 'openstack-glance-api':
      ensure     => "running",
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
    }
    exec { 'Create keys for pool images':
      command => 'ceph auth get-or-create client.images > /etc/ceph/ceph.client.images.keyring',
      before  => File['/etc/ceph/ceph.client.images.keyring'],
      require => [Package['ceph'], Exec['Copy config']],
      #TODO: centos conversion
      notify  => Service['openstack-glance-api'],
      returns => 0,
    }
    file { '/etc/ceph/ceph.client.images.keyring':
      owner   => glance,
      group   => glance,
      require => Exec['Create keys for pool images'],
      mode    => '0600',
    }
  }
}
