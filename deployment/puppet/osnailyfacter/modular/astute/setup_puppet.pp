notice('MODULAR: setup_puppet')

ini_setting { 'disable stringify_facts':
  ensure  => present,
  path    => '/etc/puppet/puppet.conf',
  section => 'main',
  setting => 'stringify_facts',
  value   => 'false',
}
