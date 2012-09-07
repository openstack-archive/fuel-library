class keepalived::config (
  $notification_email_to,
  $notification_email_from,
  $smtp_server,
  $smtp_connect_timeout,
  $router_id,
) {

  include concat::setup

  concat { $keepalived::variables::keepalived_conf:
    warn    => true,
  }

  concat::fragment { 'global_config':
    target  => $keepalived::variables::keepalived_conf,
    content => template( "${module_name}/global_config.erb" ),
    order   => '01',
  }
}
