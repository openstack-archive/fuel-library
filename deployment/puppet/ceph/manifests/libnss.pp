# set up the OS-specific libnss package for Ceph
class ceph::libnss {
  package {$::ceph::params::package_libnss:
    ensure => 'latest',
  }

  file {$::ceph::rgw_nss_db_path:
    ensure  => 'directory',
    mode    => '0755',
    require => Package['ceph']
  }
}

