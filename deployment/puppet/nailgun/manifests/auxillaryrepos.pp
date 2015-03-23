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

  exec { "create_ubuntu_repo_dirs":
    path     => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => "bash -c \"mkdir -p ${ubuntu_dir}/pool ${ubuntu_dir}/dists/auxillary/{main,restricted}/{binary-amd64,binary-i386}/\"",
    creates => "${ubuntu_dir}/pool",
  }
  exec { "create_ubuntu_repo_Packages":
    path     => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => "bash -c \"touch ${ubuntu_dir}/pool ${ubuntu_dir}/dists/auxillary/{main,restricted}/{binary-amd64,binary-i386}/Packages\"",
    creates => "${ubuntu_dir}/dists/auxillary/main/binary-amd64/Packages",
  }
}
