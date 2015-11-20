notice('MODULAR: setup_repositories.pp')

$repositories_yaml_file = '/tmp/repositories.yaml'
$repositories = loadyaml($repositories_yaml_file)

if empty($repositories) {
  fail('No repositories found in /tmp/repositories.yaml')
}

create_resources(apt::source, $repositories)
