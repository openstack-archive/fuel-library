# enable an Apache module
define apache::loadmodule () {
  exec { "/usr/sbin/a2enmod ${name}" :
    unless => "/bin/readlink -e /etc/apache2/mods-enabled/${name}.load",
    notify => Service['httpd']
  }
}

# deploys Ceph radosgw as an Apache FastCGI application
class ceph::radosgw (
  $rgw_id   = 'radosgw.gateway',
  $rgw_user = $::ceph::params::user_httpd,
  $use_ssl  = $::ceph::use_ssl,

  # RadosGW settings
  $rgw_host                         = $::ceph::rgw_host,
  $rgw_port                         = $::ceph::rgw_port,
  $swift_endpoint_port              = $::ceph::swift_endpoint_port,
  $rgw_keyring_path                 = $::ceph::rgw_keyring_path,
  $rgw_socket_path                  = $::ceph::rgw_socket_path,
  $rgw_log_file                     = $::ceph::rgw_log_file,
  $rgw_data                         = $::ceph::rgw_data,
  $rgw_dns_name                     = $::ceph::rgw_dns_name,
  $rgw_print_continue               = $::ceph::rgw_print_continue,

  #rgw Keystone settings
  $rgw_use_pki                      = $::ceph::rgw_use_pki,
  $rgw_use_keystone                 = $::ceph::rgw_use_keystone,
  $rgw_keystone_url                 = $::ceph::rgw_keystone_url,
  $rgw_keystone_admin_token         = $::ceph::rgw_keystone_admin_token,
  $rgw_keystone_token_cache_size    = $::ceph::rgw_keystone_token_cache_size,
  $rgw_keystone_accepted_roles      = $::ceph::rgw_keystone_accepted_roles,
  $rgw_keystone_revocation_interval = $::ceph::rgw_keystone_revocation_interval,
  $rgw_nss_db_path                  = $::ceph::rgw_nss_db_path,
) {

  $keyring_path     = "/etc/ceph/keyring.${rgw_id}"
  $radosgw_auth_key = "client.${rgw_id}"
  $dir_httpd_root   = '/var/www/radosgw'

  package { [$::ceph::params::package_radosgw,
             $::ceph::params::package_fastcgi,
             $::ceph::params::package_libnss,
            ]:
    ensure  => 'installed',
  }

  service { 'radosgw':
    ensure  => 'running',
    name    => $::ceph::params::service_radosgw,
    enable  => true,
    require => Package[$::ceph::params::package_radosgw],
  }
  Package<| title == $::ceph::params::package_radosgw|> ~>
  Service<| title == 'radosgw'|>
  if !defined(Service['radosgw']) {
    notify{ "Module ${module_name} cannot notify service radosgw\
 on package ${::ceph::params::package_radosgw} update": }
  }

  # The Ubuntu upstart script is incompatible with the upstart provider
  #  This will force the service to fall back to the debian init script
  if ($::operatingsystem == 'Ubuntu') {
    Service['radosgw'] {
      provider  => 'debian'
    }
  }

  if !(defined('horizon') or
       defined($::ceph::params::package_httpd) or
       defined($::ceph::params::service_httpd) ) {
    package {$::ceph::params::package_httpd:
      ensure => 'installed',
    }
    service { 'httpd':
      ensure => 'running',
      name   => $::ceph::params::service_httpd,
      enable => true,
    }
  }

  firewall {'012 RadosGW allow':
    chain   => 'INPUT',
    dport   => [ $rgw_port, $swift_endpoint_port ],
    proto   => 'tcp',
    action  => accept,
  }

  # All files need to be owned by the rgw / http user.
  File {
    owner => $rgw_user,
    group => $rgw_user,
  }

  ceph_conf {
    "client.${rgw_id}/host":                value => $rgw_host;
    "client.${rgw_id}/keyring":             value => $keyring_path;
    "client.${rgw_id}/rgw_socket_path":     value => $rgw_socket_path;
    "client.${rgw_id}/log_file":            value => $rgw_log_file;
    "client.${rgw_id}/user":                value => $rgw_user;
    "client.${rgw_id}/rgw_data":            value => $rgw_data;
    "client.${rgw_id}/rgw_dns_name":        value => $rgw_dns_name;
    "client.${rgw_id}/rgw_print_continue":  value => $rgw_print_continue;
  }

  if ($use_ssl) {

    $httpd_ssl = $::ceph::params::dir_httpd_ssl
    exec {'copy OpenSSL certificates':
      command => "scp -r ${rgw_nss_db_path}/* ${::ceph::primary_mon}:${rgw_nss_db_path} && \
                  ssh ${::ceph::primary_mon} '/etc/init.d/radosgw restart'",
    }
    exec {"generate SSL certificate on ${name}":
      command => "openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${httpd_ssl}apache.key -out ${httpd_ssl}apache.crt -subj '/C=RU/ST=Russia/L=Saratov/O=Mirantis/OU=CA/CN=localhost'",
      returns => [0,1],
    }
  }

  if ($rgw_use_keystone) {

    ceph_conf {
      "client.${rgw_id}/rgw_keystone_url":                 value => $rgw_keystone_url;
      "client.${rgw_id}/rgw_keystone_admin_token":         value => $rgw_keystone_admin_token;
      "client.${rgw_id}/rgw_keystone_accepted_roles":      value => $rgw_keystone_accepted_roles;
      "client.${rgw_id}/rgw_keystone_token_cache_size":    value => $rgw_keystone_token_cache_size;
      "client.${rgw_id}/rgw_keystone_revocation_interval": value => $rgw_keystone_revocation_interval;
    }

    if ($rgw_use_pki) {

      ceph_conf {
      "client.${rgw_id}/nss db path": value => $rgw_nss_db_path;
      }

      # This creates the signing certs used by radosgw to check cert revocation
      #   status from keystone
      exec {'create nss db signing certs':
        command => "openssl x509 -in /etc/keystone/ssl/certs/ca.pem -pubkey | \
          certutil -d ${rgw_nss_db_path} -A -n ca -t 'TCu,Cu,Tuw' && \
          openssl x509 -in /etc/keystone/ssl/certs/signing_cert.pem -pubkey | \
          certutil -A -d ${rgw_nss_db_path} -n signing_cert -t 'P,P,P'",
        user    => $rgw_user,
      }

      Exec["ceph-create-radosgw-keyring-on ${name}"] ->
      Exec['create nss db signing certs'] ~>
      Service['radosgw']

    } #END rgw_use_pki

  class {'ceph::keystone': }

  } #END rgw_use_keystone

  if ($::osfamily == 'Debian'){
    #a2mod is provided by horizon module
    a2mod { ['rewrite', 'fastcgi']:
      ensure => present,
    }

    file {'/etc/apache2/sites-enabled/rgw.conf':
      ensure => link,
      target => "${::ceph::params::dir_httpd_sites}/rgw.conf",
      notify => Service['httpd'],
    }

    Package[$::ceph::params::package_fastcgi] ->
    File["${::ceph::params::dir_httpd_sites}/rgw.conf"] ->
    File['/etc/apache2/sites-enabled/rgw.conf'] ->
    A2mod[['rewrite', 'fastcgi']] ~>
    Service['httpd']

  } #END osfamily Debian

  file {$rgw_log_file:
    ensure => present,
    mode   => '0755'
  }

  file {[$::ceph::params::dir_httpd_ssl,
         "${::ceph::rgw_data}/ceph-${rgw_id}",
         $::ceph::rgw_data,
         $dir_httpd_root,
         $rgw_nss_db_path,
        ]:
    ensure  => 'directory',
    mode    => '0755',
    recurse => true,
  }

  file { "${::ceph::params::dir_httpd_sites}/rgw.conf":
    content => template('ceph/rgw.conf.erb'),
  }

  file { "${dir_httpd_root}/s3gw.fcgi":
    content => template('ceph/s3gw.fcgi.erb'),
    mode    => '0755',
  }

  file {"${::ceph::params::dir_httpd_sites}/fastcgi.conf":
    content => template('ceph/fastcgi.conf.erb'),
    mode    => '0755',
    }

  exec { "ceph create ${radosgw_auth_key}":
    command => "ceph auth get-or-create ${radosgw_auth_key} osd 'allow rwx' mon 'allow rw'",
  }

  exec { "Populate ${radosgw_auth_key} keyring":
    command => "ceph auth get-or-create ${radosgw_auth_key} > ${keyring_path}",
    creates => $keyring_path
  }

  file { $keyring_path: mode => '0640', }

  Ceph_conf <||> ->
  Package[$::ceph::params::package_httpd] ->
  Package[[$::ceph::params::package_radosgw,
           $::ceph::params::package_fastcgi,
           $::ceph::params::package_libnss,]] ->
  File[["${::ceph::params::dir_httpd_sites}/rgw.conf",
        "${::ceph::params::dir_httpd_sites}/fastcgi.conf",
        "${dir_httpd_root}/s3gw.fcgi",
        $::ceph::params::dir_httpd_ssl,
        "${::ceph::rgw_data}/ceph-${rgw_id}",
        $::ceph::rgw_data,
        $dir_httpd_root,
        $rgw_nss_db_path,
        $rgw_log_file,]] ->
  Exec["ceph create ${radosgw_auth_key}"] ->
  Exec["Populate ${radosgw_auth_key} keyring"] ->
  File[$keyring_path] ->
  Firewall['012 RadosGW allow'] ~>
  Service ['httpd'] ~>
  Service['radosgw']
}
