notice('MODULAR: setup_repositories.pp')
include ::apt

$repositories = hiera(repositories, {})

if ! empty($repositories) {
  create_resources(apt::source, $repositories)
}

apt::conf { 'AllowUnathenticated':
  content       => 'APT::Get::AllowUnauthenticated 1;',
  priority      => '02',
  notify_update => false,
}

Apt::Source<||> ~> Exec<| title == 'apt_update' |>
