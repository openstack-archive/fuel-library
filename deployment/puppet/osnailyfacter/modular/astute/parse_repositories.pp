notice('MODULAR: parse_repositories.pp')
$repositories_yaml_file = '/tmp/repositories.yaml'

$repo_setup = hiera_hash(repo_setup, {})
if empty($repo_setup[repos]) {
  fail('No repositories found in astute.yaml')
}
$repos = $repo_setup[repos]

file { $repositories_yaml_file:
  ensure  => 'present',
  mode    => '0644',
  owner   => 'root',
  group   => 'root',
  content => template("${module_name}/repositories.yaml.erb")
}
