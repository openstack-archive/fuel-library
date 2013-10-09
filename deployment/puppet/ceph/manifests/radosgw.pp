# enable an Apache module
define apache::loadmodule () {
  exec { "/usr/sbin/a2enmod ${name}" :
    unless => "/bin/readlink -e /etc/apache2/mods-enabled/${name}.load",
    notify => Service['httpd']
  }
}

# deploys Ceph radosgw as an Apache FastCGI application
class ceph::radosgw (
  $keyring_path     = '/etc/ceph/keyring.radosgw.gateway',
  $httpd_ssl        = $::ceph::params::dir_httpd_ssl,
  $radosgw_auth_key = 'client.radosgw.gateway',
  $rgw_user         = $::ceph::params::user_httpd,

  # RadosGW settings
  $rgw_host                         = $::ceph::rgw_host,
  $rgw_port                         = $::ceph::rgw_port,
  $rgw_keyring_path                 = $::ceph::rgw_keyring_path,
  $rgw_socket_path                  = $::ceph::rgw_socket_path,
  $rgw_log_file                     = $::ceph::rgw_log_file,
  $rgw_keystone_url                 = $::ceph::rgw_keystone_url,
  $rgw_keystone_admin_token         = $::ceph::rgw_keystone_admin_token,
  $rgw_keystone_token_cache_size    = $::ceph::rgw_keystone_token_cache_size,
  $rgw_keystone_accepted_roles      = $::ceph::rgw_keystone_accepted_roles,
  $rgw_keystone_revocation_interval = $::ceph::rgw_keystone_revocation_interval,
  $rgw_data                         = $::ceph::rgw_data,
  $rgw_dns_name                     = $::ceph::rgw_dns_name,
  $rgw_print_continue               = $::ceph::rgw_print_continue,
  $rgw_nss_db_path                  = $::ceph::rgw_nss_db_path,

  $use_ssl   = $::ceph::use_ssl,
) {

  $dir_httpd_root = '/var/www/radosgw'

  package { [$::ceph::params::package_radosgw,
             $::ceph::params::package_fastcgi,
             $::ceph::params::package_modssl
            ]:
    ensure  => 'latest',
  }

  service { 'radosgw':
    ensure  => 'running',
    name    => $::ceph::params::service_radosgw,
    enable  => true,
  }

  if !(defined('horizon') or 
       defined($::ceph::params::package_httpd) or
       defined($::ceph::params::service_httpd) ) {
    package {$::ceph::params::package_httpd:
      ensure => 'latest',
    }
    service { 'httpd':
      ensure => 'running',
      name   => $::ceph::params::service_httpd,
      enable => true,
    }
  }

  # All files need to be owned by the rgw / http user.
  File {
    owner    => $rgw_user,
    group    => $rgw_user,
  }

  ceph_conf {
    'client.radosgw.gateway/host':                             value => $rgw_host;
    'client.radosgw.gateway/keyring':                          value => $keyring_path;
    'client.radosgw.gateway/rgw_socket_path':                  value => $rgw_socket_path;
    'client.radosgw.gateway/log_file':                         value => $rgw_log_file;
    'client.radosgw.gateway/user':                             value => $rgw_user;
    'client.radosgw.gateway/rgw_keystone_url':                 value => $rgw_keystone_url;
    'client.radosgw.gateway/rgw_keystone_admin_token':         value => $rgw_keystone_admin_token;
    'client.radosgw.gateway/rgw_keystone_accepted_roles':      value => $rgw_keystone_accepted_roles;
    'client.radosgw.gateway/rgw_keystone_token_cache_size':    value => $rgw_keystone_token_cache_size;
    'client.radosgw.gateway/rgw_keystone_revocation_interval': value => $rgw_keystone_revocation_interval;
    'client.radosgw.gateway/rgw_data':                         value => $rgw_data;
    'client.radosgw.gateway/rgw_dns_name':                     value => $rgw_dns_name;
    'client.radosgw.gateway/rgw_print_continue':               value => $rgw_print_continue;
  }

# TODO: CentOS conversion
#  apache::loadmodule{['rewrite', 'fastcgi', 'ssl']: }

#  file {"${::ceph::params::dir_httpd_conf}/httpd.conf":
#    ensure  => 'present',
#    content => "ServerName ${fqdn}",
#    notify  => Service['httpd'],
#    require => Package[$::ceph::params::package_httpd],
#  }

  file {$rgw_log_file:
    ensure => present,
    mode   => '0755'
  }

  file {[$::ceph::params::dir_httpd_ssl,
         "${::ceph::rgw_data}/ceph-radosgw.gateway",
         $::ceph::rgw_data,
         $dir_httpd_root,
        ]:
    ensure => 'directory',
    mode   => '0755',
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
  }

  file { "${dir_httpd_root}/s3gw.fcgi":
    content => template('ceph/s3gw.fcgi.erb'),
    mode    => '0755',
  }

  exec { "ceph-create-radosgw-keyring-on ${name}":
    command => "ceph-authtool --create-keyring ${keyring_path}",
    creates => $keyring_path,
  }

  file { $keyring_path: mode => '0640', }

  exec { "ceph-generate-key-on ${name}":
    command => "ceph-authtool ${keyring_path} -n ${radosgw_auth_key} --gen-key",
  }

  exec { "ceph-add-capabilities-to-the-key-on ${name}":
    command => "ceph-authtool -n ${radosgw_auth_key} --cap osd 'allow rwx' --cap mon 'allow rw' ${keyring_path}",
  }

  exec { "ceph-add-to-ceph-keyring-entries-on ${name}":
    command => "ceph -k /etc/ceph/ceph.client.admin.keyring auth add ${radosgw_auth_key} -i ${keyring_path}",
  }

  Ceph_conf <||> ->
  Package[[$::ceph::params::package_httpd,
           $::ceph::params::package_radosgw,]] ->
  File[["${::ceph::params::dir_httpd_sites}/rgw.conf",
       $::ceph::params::dir_httpd_ssl,
       "${::ceph::rgw_data}/ceph-radosgw.gateway",
       $::ceph::rgw_data,
       $dir_httpd_root,
       $rgw_log_file,]] ->
  Exec["ceph-create-radosgw-keyring-on ${name}"] ->
  File[$keyring_path] ->
  Exec["ceph-generate-key-on ${name}"] ->
  Exec["ceph-add-capabilities-to-the-key-on ${name}"] ->
  Exec["ceph-add-to-ceph-keyring-entries-on ${name}"] ~>
  Service ['httpd'] ~>
  Service['radosgw']
}
