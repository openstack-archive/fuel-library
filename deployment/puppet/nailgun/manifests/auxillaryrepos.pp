class nailgun::auxillaryrepos(
  $repo_root  = '/var/www/nailgun',
  ){

  $centos_dir = "${repo_root}/centos/auxillary/"
  $ubuntu_dir = "${repo_root}/ubuntu/auxillary/"

  file { $centos_dir:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }
  File[$centos_dir} ->
    Package['createrepo'] ->
      Exec["createrepo ${centos_dir}"]

  package { 'createrepo':
    ensure => latest,
  }

  exec { "createrepo ${centos_dir}":
    path     => '/bin:/sbin:/usr/bin:/usr/sbin',
    cwd      => $centos_dir,
    creates  => "${centos_dir}/repodata/repomd.xml",
  }

  file { $ubuntu_dir:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { "${ubuntu_dir}/Packages":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }
}
