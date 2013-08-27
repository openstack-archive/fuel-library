define apache::loadmodule () {
  exec { "/usr/sbin/a2enmod $name" :
    unless => "/bin/readlink -e /etc/apache2/mods-enabled/${name}.load",
    notify => Service[apache2]
  }
}

define ceph::radosgw (
  $keyring_path     = '/etc/ceph/keyring.radosgw.gateway',
  $apache2_ssl      = '/etc/apache2/ssl/',
  $radosgw_auth_key = 'client.radosgw.gateway',
) {
  package { ["apache2", "libapache2-mod-fastcgi", 'libnss3-tools', 'radosgw']:
    ensure  => "latest",
  }

  apache::loadmodule{["rewrite", "fastcgi", "ssl"]: }

  file {'/etc/apache2/httpd.conf':
    ensure  => "present",
    content => "ServerName ${fqdn}",
    notify  => Service["apache2"],
    require => Package["apache2"],
  }
  file {["${apache2_ssl}", '/var/lib/ceph/radosgw/ceph-radosgw.gateway', '/var/lib/ceph/radosgw', '/etc/ceph/nss']:
  ensure => "directory",
  mode   => 755,
  }
  exec {"generate SSL certificate on $name":
    command => "openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${apache2_ssl}apache.key -out ${apache2_ssl}apache.crt -subj '/C=RU/ST=Russia/L=Saratov/O=Mirantis/OU=CA/CN=localhost'",
    returns => [0,1],
  }
  file { "/etc/apache2/sites-available/rgw.conf":
    content => template('ceph/rgw.conf.erb'),
    notify  => Service["apache2"],
    require => Package["apache2"],
  }
  Exec {require => File["/etc/apache2/sites-available/rgw.conf"]}
  exec {'a2ensite rgw.conf':}
  exec {'a2dissite default':}
  file { "/var/www/s3gw.fcgi":
    content => template('ceph/s3gw.fcgi.erb'),
    notify  => Service["apache2"],
    require => Package["apache2"],
    mode    => "+x",
  }
  exec { "ceph-create-radosgw-keyring-on $name":
    command => "ceph-authtool --create-keyring ${keyring_path}",
    require => Package['ceph'],
  } ->
  file { "${keyring_path}":
    mode    => "+r",
  } ->
  exec { "ceph-generate-key-on $name":
    command => "ceph-authtool ${keyring_path} -n ${radosgw_auth_key} --gen-key",
    require => Package["apache2"],
  } ->
  exec { "ceph-add-capabilities-to-the-key-on $name":
    command => "ceph-authtool -n ${radosgw_auth_key} --cap osd 'allow rwx' --cap mon 'allow rw' ${keyring_path}",
    require => Package["apache2"],
  } ->
  exec { "ceph-add-to-ceph-keyring-entries-on $name":
    command => "ceph -k /etc/ceph/ceph.client.admin.keyring auth add ${radosgw_auth_key} -i ${keyring_path}",
    require => Package["apache2"],
  }
  service { "apache2":
    enable => true,
    ensure => "running",
  }
}
