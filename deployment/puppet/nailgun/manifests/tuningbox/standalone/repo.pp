class nailgun::tuningbox::standalone::repo (
  $app_name         = $::nailgun::tuningbox::params::app_name,
  $extra_repos_path = $::nailgun::tuningbox::params::extra_repos_path,
  $repo_file_name   = $::nailgun::tuningbox::params::repo_file_name,
  $repo_priority    = $::nailgun::tuningbox::params::repo_priority,
  ) inherits nailgun::tuningbox::params {

  exec {'unpack_repo':
    path        => '/usr/bin:/bin:/usr/sbin:/sbin',
    cwd         => "${extra_repos_path}",
    command     => "tar -zxvf ${extra_repos_path}/${repo_file_name}",
    refreshonly => true,
  }
  
  file { 'copy_tuningbox_repo':
     path   => "${extra_repos_path}/${repo_file_name}",
     source => "puppet:///modules/nailgun/tuningbox/${repo_file_name}",
  }
  
  yumrepo { "${app_name}":
    name     => $app_name,
    descr    => $app_name,
    baseurl  => "file://${extra_repos_path}/${app_name}",
    gpgcheck => '0',
    priority => $repo_priority,
  }

  File['copy_tuningbox_repo'] ~> Exec['unpack_repo'] -> Yumrepo["${app_name}"]
}
