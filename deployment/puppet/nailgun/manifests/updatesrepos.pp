class nailgun::updatesrepos(
  $production = $production,
  $repo_root  = '/var/www/nailgun',
  ){

  $centos_dir = "${repo_root}/centos/updates/"
  $ubuntu_dir = "${repo_root}/ubuntu/updates/"
  file { "${repo_root}/centos/updates/":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  package { 'createrepo':
    ensure => latest,
  }
  exec { "createrepo ${centos_dir}":
    path     => '/bin:/sbin:/usr/bin:/usr/sbin',
    cwd      => $centos_dir,
    creates  => "${centos_dir}/repodata/repomd.xml",
    requires => Package['createrepo'],
  }
  file { "${repo_root}/ubuntu/updates/":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }
  file { "${repo_root}/ubuntu/updates/Packages":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }
}
