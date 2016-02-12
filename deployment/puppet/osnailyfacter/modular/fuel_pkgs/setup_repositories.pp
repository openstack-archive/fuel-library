notice('MODULAR: setup_repositories.pp')

$repo_setup_hash = hiera_hash('repo_setup', {})
$repos      = $repo_setup_hash['repos']
$repo_type  = pick($repo_setup_hash['repo_type'], 'fuel')

class { '::osnailyfacter::upstream_repo_setup':
  repo_type    => $repo_type,
  uca_repo_url => $repo_setup_hash['uca_repo_url'],
  os_release   => $repo_setup_hash['uca_openstack_release'],
  pin_haproxy  => $repo_setup_hash['pin_haproxy'],
  pin_rabbitmq => $repo_setup_hash['pin_rabbitmq'],
  pin_ceph     => $repo_setup_hash['pin_ceph'],
  pin_priority => '2000',
}

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
