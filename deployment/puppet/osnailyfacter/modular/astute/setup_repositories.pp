notice('MODULAR: setup_repositories.pp')
include ::apt

$repositories_yaml_file = '/tmp/repositories.yaml'
$repositories = loadyaml($repositories_yaml_file)

if empty($repositories) {
  fail('No repositories found in /tmp/repositories.yaml')
}

create_resources(apt::source, $repositories)

apt::conf { 'AllowUnathenticated':
  content       => 'APT::Get::AllowUnauthenticated 1;',
  priority      => '02',
  notify_update => false,
}

Apt::Source<||> ~> Exec<| title == 'apt_update' |>
