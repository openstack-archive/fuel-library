class nailgun::puppetsync(
  $puppet_folder = '/etc/puppet'
  ){

  file { $puppet_folder:
    ensure => 'directory',
  }

  class { 'rsync::server':
    use_xinetd => true,
  }

  rsync::server::module { 'puppet':
    path   => $puppet_folder,
    require => File[$puppet_folder],
    list  => true,
    read_only => true,
  }
}