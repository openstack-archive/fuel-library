notice('MODULAR: parse_repositories.pp')

$repositories_yaml_file = '/etc/hiera/repositories.yaml'
$repo_setup = hiera(repo_setup, {})
$repos = $repo_setup[repos]

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
