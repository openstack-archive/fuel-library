# == Class: glance::notify::qpid
#
# used to configure qpid notifications for glance
#
# === Parameters:
#
# [*qpid_password*]
#   (required) Password to connect to the qpid server.
#
# [*qpid_username*]
#   (Optional) User to connect to the qpid server.
#   Defaults to 'guest'.
#
# [*qpid_hostname*]
#   (Optional) IP or hostname of the qpid server.
#   Defaults to 'localhost'.
#
# [*qpid_port*]
#   (Optional) Port of the qpid server.
#   Defaults to 5672.
#
# [*qpid_protocol*]
#   (Optional) Protocol to use for qpid (tcp/ssl).
#   Defaults to tcp.
#
class glance::notify::qpid(
  $qpid_password,
  $qpid_username = 'guest',
  $qpid_hostname = 'localhost',
  $qpid_port     = '5672',
  $qpid_protocol = 'tcp'
) inherits glance::api {

  glance_api_config {
    'DEFAULT/notifier_driver':   value => 'qpid';
    'DEFAULT/qpid_hostname':     value => $qpid_hostname;
    'DEFAULT/qpid_port':         value => $qpid_port;
    'DEFAULT/qpid_protocol':     value => $qpid_protocol;
    'DEFAULT/qpid_username':     value => $qpid_username;
    'DEFAULT/qpid_password':     value => $qpid_password, secret => true;
  }

}
