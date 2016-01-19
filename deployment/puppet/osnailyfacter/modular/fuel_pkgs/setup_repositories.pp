notice('MODULAR: setup_repositories.pp')

$repo_setup = hiera('repo_setup', {})
$repos      = $repo_setup['repos']
$ceph_packages = ['ceph', 'ceph-common', 'libradosstriper1', 'python-ceph',
  'python-rbd', 'python-rados', 'python-cephfs', 'libcephfs1', 'librados2',
  'librbd1', 'radosgw', 'rbd-fuse']

if $::osfamily == 'Debian' {
  include ::apt

  $repositories = generate_apt_sources($repos)
  $pins         = generate_apt_pins($repos)

  if ! empty($repositories) {
    create_resources(apt::source, $repositories)
  }

  if ! empty($pins) {
    create_resources(apt::pin, $pins)
  }

  Apt::Conf {
    notify_update => false,
    priority      => '02',
  }


  # TODO(aschultz): we need the mos fork haproxy when using UCA
  apt::pin { 'haproxy-mos':
    packages => 'haproxy',
    version  => '1.5.3-*',
    priority => '2000',
  }

  # TODO(mattymo): we need the mos fork ceph when using UCA
  apt::pin { 'ceph-mos':
    packages => $ceph_packages,
    version  => '0.94*',
    priority => '2000',
  }

  # TODO(mattymo): we need the mos fork rabbitmq when using UCA
  apt::pin { 'rabbitmq-server-mos':
    packages => 'rabbitmq-server',
    version  => '3.5.6-*',
    priority => '2000',
  }

  apt::conf { 'allow-unathenticated':
    content => 'APT::Get::AllowUnauthenticated 1;',
  }

  apt::conf { 'install-recommends':
    content => 'APT::Install-Recommends "false";',
  }

  apt::conf { 'install-suggests':
    content => 'APT::Install-Suggests "false";',
  }

  Apt::Source<||> ~> Exec<| title == 'apt_update' |>
}
