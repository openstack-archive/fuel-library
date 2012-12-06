define keepalived::instance (
  $interface,
  $virtual_ips,
  $state,
  $priority,
  $notify        = undef,
  $notify_master = undef,
  $notify_backup = undef,
  $notify_fault  = undef,
  $smtp_alert    = false,
  $vrrp_script   = undef,
  $interval = '2',
  $weight = '2',
) {

  include keepalived::variables

  concat::fragment { "keepalived_${name}":
    target  => $keepalived::variables::keepalived_conf,
    content => template( 'keepalived/keepalived_instance.erb' ),
    order   => '50',
    notify  => Class[ 'keepalived::service' ],
    require => Class[ 'keepalived::install' ],
  }
}
