class puppet::pull (
  $script    = '/usr/local/bin/puppet-pull',
  $template  = 'puppet/puppet-pull.sh.erb',
  $modules_source   = 'rsync://10.20.0.2/puppet/modules',
  $manifests_source = 'rsync://10.20.0.2/puppet/manifests',
) {

  file { $script :
    ensure  => present,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template($template),
  }

}
