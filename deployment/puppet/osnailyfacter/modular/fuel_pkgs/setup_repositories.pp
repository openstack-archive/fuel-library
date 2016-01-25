notice('MODULAR: setup_repositories.pp')

$repo_setup = hiera('repo_setup', {})
$repos      = $repo_setup['repos']

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
