# set up the OS-specific libnss package for Ceph
class ceph::libnss {
  package {$::ceph::params::package_libnss:
    ensure => 'latest',
  }

  file {$::ceph::rgw_nss_db_path:
    ensure  => 'directory',
    mode    => '0755',
    owner   => $::ceph::params::user_httpd,
    group   => $::ceph::params::user_httpd,
    require => Package['ceph']
  }
}

