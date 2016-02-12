class osnailyfacter::upstream_repo_setup (
$repo_type     = unset,
$repo_url      = unset,
$repo_priority = '9000',
$pin_haproxy   = false,
$pin_rabbitmq  = false,
$pin_ceph      = false,
$pin_priority  = '2000',
$ceph_packages = ['ceph', 'ceph-common', 'libradosstriper1', 'python-ceph',
  'python-rbd', 'python-rados', 'python-cephfs', 'libcephfs1', 'librados2',
  'librbd1', 'radosgw', 'rbd-fuse']
) {

if $repo_type == 'uca' {
  #FIXME(mattmyo): derive versions via fact or hiera
  apt::pin { 'haproxy-mos':
    packages => 'haproxy',
    version  => '1.5.3-*',
    priority => '2000',
  }

  apt::pin { 'ceph-mos':
    packages => $ceph_packages,
    version  => '0.94*',
    priority => '2000',
  }

  apt::pin { 'rabbitmq-server-mos':
    packages => 'rabbitmq-server',
    version  => '3.5.6-*',
    priority => '2000',
  }
}

case $repo_type {
  'fuel': {
    notice {'No repo changes needed for Fuel repo type.': }
  }
  'uca': {
    $os_release = pick($plugin_config['uca_openstack_release'], 'mitaka')
    $repo_url   = pick($plugin_config['uca_repo_url'], 'http://ubuntu-cloud.archive.canonical.com/ubuntu')
    $release    = "${::lsbdistcodename}-updates/${os_release}"
    $repo_name  = 'UCA'
    $originator = 'Canonical'
    package { 'ubuntu-cloud-keyring':
      ensure  => 'present',
    }
  }
  'debian': {
    $os_release = pick($plugin_config['debian_trusty_openstack_release'], 'trusty-mitaka-backports')
    $repo_url   = pick($plugin_config['debian_trusty_repo_url'], 'http://mitaka-trusty.pkgs.mirantis.com/debian')
    $release    = $os_release
    $repo_name  = 'debian_trusty'
    $originator = 'Debian'
  }
  default: {
    fail("Invalid repo type ${plugin_config['repo_type']}")
  }
}

if $repo_type != 'fuel' {
  apt::source { $repo_name:
    location => $repo_url,
    release  => $release,
    repos    => 'main'
  }

  apt::pin { $repo_name:
    packages   => '*',
    release    => $release,
    originator => $originator,
    codename   => "${release}/${os_release}",
    priority   => '9000',
  }
}
