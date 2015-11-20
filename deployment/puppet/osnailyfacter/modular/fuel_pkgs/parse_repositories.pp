notice('MODULAR: parse_repositories.pp')

$repositories_yaml_file = '/tmp/repositories.yaml'
$astute_yaml_file       = '/etc/astute.yaml'

$astute_yaml = pick(loadyaml($astute_yaml_file), {})
$repos = $astute_yaml[repo_setup][repos]

if empty($repos) {
  fail('No repositories found in astute.yaml')
}

file { $repositories_yaml_file:
  ensure  => 'present',
  mode    => '0644',
  owner   => 'root',
  group   => 'root',
  content => template('osnailyfacter/repositories.yaml.erb'),
}
