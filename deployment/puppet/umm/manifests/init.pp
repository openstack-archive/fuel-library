class umm (
  $umm_enabled            = 'yes',
  $umm_reboot_count       = '2',
  $umm_counter_reset_time = '10',
)
{
  package { 'fuel-umm' :
    ensure => 'installed',
  }

  file { 'umm_config' :
    ensure                => present,
    content               => template('umm/umm.conf.erb'),
    path                  => '/etc/umm.conf',
    require               => Package['fuel-umm'],
  }
}
