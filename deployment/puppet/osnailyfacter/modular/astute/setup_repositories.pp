notice('MODULAR: setup_repositories.pp')
$repositories_yaml_file = '/tmp/repositories.yaml'

$astute_yaml = loadyaml('/etc/astute.yaml')
$repos = $astute_yaml[repo_setup][repos]

if empty($repos) {
  fail('No repositories found in astute.yaml')
}

file { $repositories_yaml_file:
  ensure  => 'present',
  mode    => '0644',
  owner   => 'root',
  group   => 'root',
  content => template('osnailyfacter/repositories.yaml.erb')
}

$repositories = loadyaml('/tmp/repositories.yaml')

if empty($repositories) {
  fail('No repositories found in /tmp/repositories.yaml')
}

create_resources(apt::source, $repositories)
