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
