class nailgun::repodata (
  $repodata_file       = '/etc/nailgun/fixtures/repodata.yaml',
  $repodata_dir        = '/etc/nailgun/fixtures',
  $master_node_ip      = '10.20.0.2',
  $repository_port     = '8080',
  $fuel_release        = undef,
  $ubuntu_repos        = 'precise main',
  $puppet_rsync_base   = 'puppet/release'
) {

  if $fuel_release {
    $centos_repo_source      = "http://${master_node_ip}:${repository_port}/centos-${fuel_release}/fuelweb/x86_64/"
    $ubuntu_repo_source      = "http://${master_node_ip}:${repository_port}/ubuntu-${fuel_release}/fuelweb/x86_64/ ${ubuntu_repos}"
    $puppet_modules_source   = "rsync://${master_node_ip}/${puppet_rsync_base}/${fuel_release}/modules/"
    $puppet_manifests_source = "rsync://${master_node_ip}/${puppet_rsync_base}/${fuel_release}/manifests/"
  } else {
    $centos_repo_source      = "http://${master_node_ip}:${repository_port}/centos/fuelweb/x86_64/"
    $ubuntu_repo_source      = "http://${master_node_ip}:${repository_port}/ubuntu/fuelweb/x86_64/ ${ubuntu_repos}"
    $puppet_modules_source   = "rsync://${master_node_ip}/puppet/modules/"
    $puppet_manifests_source = "rsync://${master_node_ip}/puppet/manifests/"
  }

  file { $repodata_dir :
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { $repodata_file :
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('nailgun/repodata.yaml.erb'),
  }

}
