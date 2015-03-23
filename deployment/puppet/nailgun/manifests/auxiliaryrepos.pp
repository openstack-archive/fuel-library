class nailgun::auxiliaryrepos(
  $repo_root  = '/var/www/nailgun',
  ){

  $centos_dir = "${repo_root}/centos/auxiliary/"
  $ubuntu_dir = "${repo_root}/ubuntu/auxiliary/"

  file { $centos_dir:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  File[$centos_dir] ->
    Package['createrepo'] ->
      Exec["createrepo ${centos_dir}"] ->
        Yumrepo['auxiliary']

  yumrepo { 'auxiliary':
    name     => "auxiliary",
    baseurl  => "file://${centos_dir}",
    gpgcheck => '0',
  }

  package { 'createrepo':
    ensure => latest,
  }

  exec { "createrepo ${centos_dir}":
    path     => '/bin:/sbin:/usr/bin:/usr/sbin',
    cwd      => $centos_dir,
    creates  => "${centos_dir}/repodata/repomd.xml",
  }

  Exec['create_ubuntu_repo_dirs'] ->
    Exec['create_ubuntu_repo_Packages']

  exec { "create_ubuntu_repo_dirs":
    path     => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => "bash -c \"mkdir -p ${ubuntu_dir}/pool/{main,restricted} ${ubuntu_dir}/dists/auxiliary/{main,restricted}/binary-amd64/\"",
    creates => "${ubuntu_dir}/pool",
  }

  exec { "create_ubuntu_repo_Packages":
    path     => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => "bash -c \"touch ${ubuntu_dir}/dists/auxiliary/{main,restricted}/binary-amd64/Packages\"",
    creates => "${ubuntu_dir}/dists/auxiliary/main/binary-amd64/Packages",
  }
}

