notice('MODULAR: parse_repositories.pp')

$repositories_yaml_file = '/tmp/repositories.yaml'
$astute_yaml_file       = '/etc/astute.yaml'
$astute_yaml_exists     = inline_template('<%= File.exists?(@astute_yaml_file) %>')

if $astute_yaml_exists == 'false' {
  fail("${astute_yaml_file} does not exist")
}

$astute_yaml = loadyaml($astute_yaml_file)
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
