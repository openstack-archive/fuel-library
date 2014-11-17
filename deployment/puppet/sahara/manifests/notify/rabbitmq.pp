#
# used to configure rabbitmq notifications for sahara
#
#  [*rabbit_password*]
#    password to connect to the rabbit_server.
#  [*rabbit_userid*]
#    user to connect to the rabbit server. Optional. Defaults to 'guest'
#  [*rabbit_host*]
#    ip or hostname of the rabbit server. Optional. Defaults to 'localhost'
#  [*rabbit_port*]
#    port of the rabbit server. Optional. Defaults to 5672.
#  [*rabbit_virtual_host*]
#    virtual_host to use. Optional. Defaults to '/'
#
class sahara::notify::rabbitmq(
  $rabbit_password,
  $rabbit_userid         = 'guest',
  $rabbit_host           = 'localhost',
  $rabbit_port           = '5672',
  $rabbit_hosts          = false,
  $rabbit_virtual_host   = '/',
  $enable_notifications  = true,
  $rabbit_use_ssl        = false,
  $kombu_ssl_ca_certs    = undef,
  $kombu_ssl_certfile    = undef,
  $kombu_ssl_keyfile     = undef,
  $kombu_ssl_version     = 'SSLv3',
  $amqp_durable_queues   = false,
  $rabbit_ha_queues      = false,
) {

  if $rabbit_hosts {
    if !is_array($rabbit_hosts) {
      $rabbit_hosts_real = split($rabbit_hosts, ',')
    } else {
      $rabbit_hosts_real = $rabbit_hosts
    }
    sahara_config { 'DEFAULT/rabbit_host': ensure => absent }
    sahara_config { 'DEFAULT/rabbit_port': ensure => absent }
    sahara_config { 'DEFAULT/rabbit_hosts': value => join($rabbit_hosts_real, ',') }
  } else {
    sahara_config { 'DEFAULT/rabbit_host': value => $rabbit_host }
    sahara_config { 'DEFAULT/rabbit_port': value => $rabbit_port }
    sahara_config { 'DEFAULT/rabbit_hosts': value => "${rabbit_host}:${rabbit_port}" }
  }

  sahara_config {
    'DEFAULT/enable_notifications': value => $enable_notifications;
    'DEFAULT/notification_driver':  value => 'messaging';
    'DEFAULT/rabbit_virtual_host':  value => $rabbit_virtual_host;
    'DEFAULT/rabbit_password':      value => $rabbit_password;
    'DEFAULT/rabbit_userid':        value => $rabbit_userid;
    'DEFAULT/rpc_backend':          value => 'rabbit';
    'DEFAULT/rabbit_use_ssl':       value => $rabbit_use_ssl;
    'DEFAULT/amqp_durable_queues':  value => $amqp_durable_queues;
    'DEFAULT/rabbit_ha_queues':     value => $rabbit_ha_queues;
  }

  if $rabbit_use_ssl {
    sahara_config { 'DEFAULT/kombu_ssl_version': value => $kombu_ssl_version }

   if $kombu_ssl_ca_certs {
      sahara_config { 'DEFAULT/kombu_ssl_ca_certs': value => $kombu_ssl_ca_certs }
    } else {
      sahara_config { 'DEFAULT/kombu_ssl_ca_certs': ensure => absent}
    }

    if $kombu_ssl_certfile {
      sahara_config { 'DEFAULT/kombu_ssl_certfile': value => $kombu_ssl_certfile }
    } else {
      sahara_config { 'DEFAULT/kombu_ssl_certfile': ensure => absent}
    }

    if $kombu_ssl_keyfile {
      sahara_config { 'DEFAULT/kombu_ssl_keyfile': value => $kombu_ssl_keyfile }
    } else {
      sahara_config { 'DEFAULT/kombu_ssl_keyfile': ensure => absent}
    }
  } else {
    sahara_config {
      'DEFAULT/kombu_ssl_version':  ensure => absent;
      'DEFAULT/kombu_ssl_ca_certs': ensure => absent;
      'DEFAULT/kombu_ssl_certfile': ensure => absent;
      'DEFAULT/kombu_ssl_keyfile':  ensure => absent;
    }
    if ($kombu_ssl_keyfile or $kombu_ssl_certfile or $kombu_ssl_ca_certs) {
      notice('Configuration of certificates with $rabbit_use_ssl == false is a useless config')
    }
  }
}
