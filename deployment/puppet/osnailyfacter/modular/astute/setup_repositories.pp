notice('MODULAR: setup_repositories.pp')
$repositories = loadyaml('/tmp/repositories.yaml')

if empty($repositories) {
  fail('No repositories found in globals.yaml')
}

create_resources(apt::source, $repositories)
