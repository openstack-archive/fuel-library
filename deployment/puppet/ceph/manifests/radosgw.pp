define apache::loadmodule () {
  exec { "/usr/sbin/a2enmod $name" :
    unless => "/bin/readlink -e /etc/apache2/mods-enabled/${name}.load",
    notify => Service['httpd']
  }
}

class ceph::radosgw (
  $keyring_path     = '/etc/ceph/keyring.radosgw.gateway',
  $httpd_ssl        = $::ceph::params::dir_httpd_ssl,
  $radosgw_auth_key = 'client.radosgw.gateway',
  #RadosGW settings
  $rgw_host                         = $::hostname,
  $rgw_keyring_path                 = '/etc/ceph/keyring.radosgw.gateway',
  $rgw_socket_path                  = '/tmp/radosgw.sock',
  $rgw_log_file                     = '/var/log/ceph/radosgw.log',
  $rgw_user                         = 'www-data',
  $rgw_keystone_url                 = "${cluster_node_address}:5000",
  $rgw_keystone_admin_token         = 'nova',
  $rgw_keystone_token_cache_size    = '10',
  $rgw_keystone_accepted_roles      = "_member_, Member, admin, swiftoperator",
  $rgw_keystone_revocation_interval = '60',
  $rgw_data                         = '/var/lib/ceph/rados',
  $rgw_dns_name                     = "*.${::domain}",
  $rgw_print_continue               = 'false',
  $rgw_nss_db_path                  = '/etc/ceph/nss',

  $use_ssl   = $::ceph::use_ssl,
  $enabled   = $::ceph::use_rgw,
) {
  if ($enabled) {
    package { [$::ceph::params::package_radiosgw,
               $::ceph::params::package_fastcgi,
               $::ceph::params::package_modssl
              ]:
      ensure  => 'latest',
    }

    if !(defined('horizon') or 
         defined($::ceph::params::package_httpd) or
         defined($::ceph::params::service_httpd) ) {
      package {$::ceph::params::package_httpd:
        ensure => 'latest',
      }
      service { 'httpd':
        name      => $::ceph::params::service_httpd,
        enable => true,
        ensure => 'running',
      }
    }

    service {$::ceph::params::service_radosgw:
      enable  => true,
      ensure  => 'running',
      require => Package[$::ceph::params::package_radiosgw]
    }
    ceph_conf {
      'client.radosgw.gateway/host':                             value => $host;
      'client.radosgw.gateway/keyring':                          value => $keyring_path;
      'client.radosgw.gateway/rgw socket path':                  value => $rgw_socket_path;
      'client.radosgw.gateway/log file':                         value => $rgw_log_file;
      'client.radosgw.gateway/user':                             value => $rgw_user;
      'client.radosgw.gateway/rgw keystone url':                 value => $rgw_keystone_url;
      'client.radosgw.gateway/rgw keystone admin token':         value => $rgw_keystone_admin_token;
      'client.radosgw.gateway/rgw keystone accepted roles':      value => $rgw_keystone_accepted_roles;
      'client.radosgw.gateway/rgw keystone token cache size':    value => $rgw_keystone_token_cache_size;
      'client.radosgw.gateway/rgw keystone revocation interval': value => $rgw_keystone_revocation_interval;
      'client.radosgw.gateway/rgw data':                         value => $rgw_data;
      'client.radosgw.gateway/rgw dns name':                     value => $rgw_dns_name;
      'client.radosgw.gateway/rgw print continue':               value => $rgw_print_continue;
    }
    #TODO: CentOS conversion
#    apache::loadmodule{['rewrite', 'fastcgi', 'ssl']: }

#    file {"${::ceph::params::dir_httpd_conf}/httpd.conf":
#      ensure  => 'present',
#      content => "ServerName ${fqdn}",
#      notify  => Service['httpd'],
#      require => Package[$::ceph::params::package_httpd],
#    }
    file {["${::ceph::params::dir_httpd_ssl}",
           '/var/lib/ceph/radosgw/ceph-radosgw.gateway',
           '/var/lib/ceph/radosgw',
          ]:
    ensure => 'directory',
    mode   => 755,
    }
    if ($use_ssl) {
      exec {"generate SSL certificate on ${name}":
        command => "openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${httpd_ssl}apache.key -out ${httpd_ssl}apache.crt -subj '/C=RU/ST=Russia/L=Saratov/O=Mirantis/OU=CA/CN=localhost'",
        returns => [0,1],
      }
      ceph_conf{
        'client.radosgw.gateway/nss db path': value => $rgw_nss_db_path;
      }
    }
    file { "${::ceph::params::dir_httpd_sites}/rgw.conf":
      content => template('ceph/rgw.conf.erb'),
      notify  => Service['httpd'],
      require => Package[$::ceph::params::package_httpd],
    }
    Exec {require => File["${::ceph::params::dir_httpd_sites}/rgw.conf"]}
    file { '/var/www/s3gw.fcgi':
      content => template('ceph/s3gw.fcgi.erb'),
      notify  => Service['httpd'],
      require => Package[$::ceph::params::package_httpd],
      mode    => '+x',
    }
    exec { "ceph-create-radosgw-keyring-on $name":
      command => "ceph-authtool --create-keyring ${keyring_path}",
      require => Package['ceph'],
    } ->
    file { "${keyring_path}":
      mode    => '+r',
    } ->
    exec { "ceph-generate-key-on $name":
      command => "ceph-authtool ${keyring_path} -n ${radosgw_auth_key} --gen-key",
      require => Package[$::ceph::params::package_httpd],
    } ->
    exec { "ceph-add-capabilities-to-the-key-on $name":
      command => "ceph-authtool -n ${radosgw_auth_key} --cap osd 'allow rwx' --cap mon 'allow rw' ${keyring_path}",
      require => Package[$::ceph::params::package_httpd],
    } ->
    exec { "ceph-add-to-ceph-keyring-entries-on $name":
      command => "ceph -k /etc/ceph/ceph.client.admin.keyring auth add ${radosgw_auth_key} -i ${keyring_path}",
      require => Package[$::ceph::params::package_httpd],
      notify  => Service[$::ceph::params::service_radosgw]
    }
  }
}
