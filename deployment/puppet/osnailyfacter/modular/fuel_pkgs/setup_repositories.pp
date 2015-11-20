notice('MODULAR: setup_repositories.pp')
$repositories = hiera(repositories, {})

if $::osfamily == 'Debian' {
  include ::apt

  if ! empty($repositories) {
    create_resources(apt::source, $repositories)
  }

  apt::conf { 'AllowUnathenticated':
    content       => 'APT::Get::AllowUnauthenticated 1;',
    priority      => '02',
    notify_update => false,
  }

  Apt::Source<||> ~> Exec<| title == 'apt_update' |>
}
