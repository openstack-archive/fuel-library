#
# used to configure qpid notifications for sahara
#
class sahara::notify::qpid(
  $qpid_password,
  $qpid_username  = 'guest',
  $qpid_hostname  = 'localhost',
  $qpid_port      = '5672',
  $qpid_iprotocol = 'tcp',
  $qpid_hosts     = false,
) {

  if $qpid_hosts {
    sahara_config {
      'DEFAULT/qpid_hosts':    value => $qpid_hosts;
      'DEFAULT/qpid_hostname': ensure => absent;
      'DEFAULT/qpid_port':     ensure => absent;
    }
  } else {
    sahara_config {
      'DEFAULT/qpid_hosts':    ensure => absent;
      'DEFAULT/qpid_hostname': value => $qpid_hostname;
      'DEFAULT/qpid_port':     value => $qpid_port;
    }
  }

  sahara_config {
    'DEFAULT/notifier_driver': value => 'messaging';
    'DEFAULT/qpid_protocol':   value => $qpid_protocol;
    'DEFAULT/qpid_username':   value => $qpid_username;
    'DEFAULT/qpid_password':   value => $qpid_password;
    'DEFAULT/rpc_backend':     value => 'qpid';
  }
}
