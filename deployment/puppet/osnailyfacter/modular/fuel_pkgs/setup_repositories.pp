notice('MODULAR: setup_repositories.pp')

$repo_setup = hiera('repo_setup', {})
$repos = $repo_setup['repos']

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

  apt::conf { 'AllowUnathenticated':
    content       => 'APT::Get::AllowUnauthenticated 1;',
    priority      => '02',
    notify_update => false,
  }

  Apt::Source<||> ~> Exec<| title == 'apt_update' |>
}
