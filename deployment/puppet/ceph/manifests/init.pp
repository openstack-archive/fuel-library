#ceph will install ceph parts
class ceph (
      #General settings
      $cluster_node_address             = $::ipaddress, #This should be the cluster service address
      $primary_mon                      = $::hostname, #This should be the first controller
      $ceph_pools                       = [ 'volumes', 'images' ],
      $osd_devices                      = split($::osd_devices_list, " "),
      #ceph.conf Global settings
      $auth_supported                   = 'cephx',
      $osd_journal_size                 = '2048',
      $osd_mkfs_type                    = 'xfs',
      $osd_pool_default_size            = '2',
      $osd_pool_default_min_size        = '1',
      #TODO: calculate PG numbers
      $osd_pool_default_pg_num          = '100',
      $osd_pool_default_pgp_num         = '100',
      $cluster_network                  = "${::storage_network_range}",
      $public_network                   = "${::management_network_range}",
      #RadosGW settings
      $host                             = $::hostname,
      $keyring_path                     = '/etc/ceph/keyring.radosgw.gateway',
      $rgw_socket_path                  = '/tmp/radosgw.sock',
      $log_file                         = '/var/log/ceph/radosgw.log',
      $user                             = 'www-data',
      $rgw_keystone_url                 = "${cluster_node_address}:5000",
      $rgw_keystone_admin_token         = 'nova',
      $rgw_keystone_token_cache_size    = '10',
      $rgw_keystone_accepted_roles      = undef, #TODO: find a default value for this
      $rgw_keystone_revocation_interval = '60',
      $rgw_data                         = '/var/lib/ceph/rados',
      $rgw_dns_name                     = $::hostname,
      $rgw_print_continue               = 'false',
      $nss_db_path                      = '/etc/ceph/nss',
      #Cinder settings
      $volume_driver                    = 'cinder.volume.drivers.rbd.RBDDriver',
      $rbd_pool                         = 'volumes',
      $glance_api_version               = '2',
      $rbd_user                         = 'volumes',
      #TODO: generate rbd_secret_uuid
      $rbd_secret_uuid                  = 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',
      #Glance settings
      $default_store                    = 'rbd',
      $rbd_store_user                   = 'images',
      $rbd_store_pool                   = 'images',
      $show_image_direct_url            = 'True',
      #Keystone settings
      $rgw_pub_ip                       = "${cluster_node_address}",
      $rgw_adm_ip                       = "${cluster_node_address}",
      $rgw_int_ip                       = "${cluster_node_address}",
) {

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
         cwd  => '/root',
  }
  ceph_conf {
    'global/auth supported':                                   value => $auth_supported;
    'global/osd journal size':                                 value => $osd_journal_size;
    'global/osd mkfs type':                                    value => $osd_mkfs_type;
    'global/osd pool default size':                            value => $osd_pool_default_size;
    'global/osd pool default min size':                        value => $osd_pool_default_min_size;
    'global/osd pool default pg num':                          value => $osd_pool_default_pg_num;
    'global/osd pool default pgp num':                         value => $osd_pool_default_pgp_num;
    'global/cluster network':                                  value => $cluster_network;
    'global/public network':                                   value => $public_network;
    'client.radosgw.gateway/host':                             value => $host;
    'client.radosgw.gateway/keyring':                          value => $keyring_path;
    'client.radosgw.gateway/rgw socket path':                  value => $rgw_socket_path;
    'client.radosgw.gateway/log file':                         value => $log_file;
    'client.radosgw.gateway/user':                             value => $user;
    'client.radosgw.gateway/rgw keystone url':                 value => $rgw_keystone_url;
    'client.radosgw.gateway/rgw keystone admin token':         value => $rgw_keystone_admin_token;
    'client.radosgw.gateway/rgw keystone accepted roles':      value => $rgw_keystone_accepted_roles;
    'client.radosgw.gateway/rgw keystone token cache size':    value => $rgw_keystone_token_cache_size;
    'client.radosgw.gateway/rgw keystone revocation interval': value => $rgw_keystone_revocation_interval;
    'client.radosgw.gateway/rgw data':                         value => $rgw_data;
    'client.radosgw.gateway/rgw dns name':                     value => $rgw_dns_name;
    'client.radosgw.gateway/rgw print continue':               value => $rgw_print_continue;
    'client.radosgw.gateway/nss db path':                      value => $nss_db_path;
  }
  Ceph_conf {require => Exec['ceph-deploy init config']}
  #RE-enable this if not using fuelweb iso with Ceph packages
  #include 'ceph::yum'
  include 'ceph::params'
  include 'ceph::ssh'
  #TODO: this should be pulled back into existing modules for setting up ssh-key
  #TODO: OR need to at least generate the key

  #Prepare nodes for futher actions
  #TODO: add ceph service
  if $::hostname == $::ceph::primary_mon {
    exec { 'ceph-deploy init config':
      command   => "ceph-deploy new ${::hostname}:${::internal_address}",
      cwd       => '/etc/ceph',
      require   => Package['ceph-deploy', 'ceph'],
      logoutput => true,
      creates   => ['/etc/ceph/ceph.conf'],
    } -> file {'/root/ceph.conf':
      #link is necessary to work around http://tracker.ceph.com/issues/6281
      ensure => link, 
      target => '/etc/ceph/ceph.conf',
    } -> file {'/root/ceph.mon.keyring':
      ensure => link,
      target => '/etc/ceph/ceph.mon.keyring',
    } ->  Ceph_conf <||>
  } else {
    exec {'ceph-deploy config pull':
      command => "ceph-deploy --overwrite-conf config pull ${::ceph::primary_mon}",
      require => Package['ceph-deploy', 'ceph'],
      creates => '/root/ceph.conf',
      }
    exec {'ceph-deploy gatherkeys remote':
      command => "ceph-deploy gatherkeys ${::ceph::primary_mon}",
      require => [Exec['ceph-deploy config pull']],
      creates => ['/root/ceph.bootstrap-mds.keyring',
                  '/root/ceph.bootstrap-osd.keyring',
                  '/root/ceph.admin.keyring',
                  '/root/ceph.mon.keyring'
                 ],
    }
    exec {'ceph-deploy init config':
      command => "ceph-deploy --overwrite-conf config push ${::hostname}",
      require => [Exec['ceph-deploy gatherkeys remote']],
      creates => '/etc/ceph/ceph.conf',
    }
  }
  case $::role {
    'primary-controller', 'controller', 'ceph-mon': {
      class {['ceph::glance', 'ceph::cinder', 'ceph::nova_compute']: }
      class {'ceph::mon':
      } -> Class[['ceph::glance',
                  'ceph::cinder',
                  'ceph::nova_compute',
                  #'ceph::keystone', #ceph::keystone is currently disabled
                ]]
      #include ceph::keystone #Keystone is currently disabled
    }
    #TODO: remove cinder from this list.
    #This will still NOOP on cinder if $::osd_device_list is empty
    'ceph-osd', 'cinder': {
      class {'ceph::osd': }
    }
    'ceph-mds': {
      class {'ceph::deploy': }
    }
    'compute': {
      class {'ceph::nova_compute': }
    }
    default: {
      #TODO: this is probably too aggressive
      include ceph::cinder, ceph::nova_compute
    }
  }

}
