class nailgun::auxiliaryrepos(
  $repo_root  = '/var/www/nailgun',
  $priority = '15',
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
    name     => 'auxiliary',
    descr    => 'auxillary',
    baseurl  => "file://${centos_dir}",
    gpgcheck => '0',
    priority => $priority,
  }

  package { 'createrepo':
    ensure => latest,
  }

  exec { "createrepo ${centos_dir}":
    path     => '/bin:/sbin:/usr/bin:/usr/sbin',
    cwd      => $centos_dir,
    creates  => "${centos_dir}/repodata/repomd.xml",
  }

  $release_files = [
    "${ubuntu_dir}/dists/auxiliary/Release",
    "${ubuntu_dir}/dists/auxiliary/main/binary-amd64/Release",
    "${ubuntu_dir}/dists/auxiliary/restricted/binary-amd64/Release"]

  Exec['create_ubuntu_repo_dirs'] ->
    Exec['create_ubuntu_repo_Packages'] ->
      File[$release_files]

  exec { 'create_ubuntu_repo_dirs':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => "bash -c \"mkdir -p ${ubuntu_dir}/pool/{main,restricted} ${ubuntu_dir}/dists/auxiliary/{main,restricted}/binary-amd64/\"",
    unless => "test -d ${ubuntu_dir}/pool && \
      test -d ${ubuntu_dir}/dists/auxiliary/main/binary-amd64 && \
      test -d ${ubuntu_dir}/dists/auxiliary/restricted/binary-amd64",
  }

  exec { 'create_ubuntu_repo_Packages':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => "bash -c \"touch ${ubuntu_dir}/dists/auxiliary/{main,restricted}/binary-amd64/Packages\"",
    unless  => "test -f ${ubuntu_dir}/dists/auxiliary/main/binary-amd64/Packages && \
      test -f ${ubuntu_dir}/dists/auxiliary/restricted/binary-amd64/Packages",
  }

  file { $release_files:
    ensure  => file,
    replace => false,
    source  => 'puppet:///modules/nailgun/Release-auxiliary',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }
}
