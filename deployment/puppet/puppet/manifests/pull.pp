class puppet::pull (
  $master_ip = '10.20.0.2',
  $script    = '/usr/local/bin/puppet-pull',
  $template  = 'puppet/puppet-pull.sh.erb',
) {

  file { $script :
    ensure  => present,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template($template),
  }

}
