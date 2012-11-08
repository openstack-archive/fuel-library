# == Class: keepalived
#
# This class setup the basis for keeapalive, knowingly package installation
# and some global variables.
#
# The keepalived::instance define depends on this class.
#
# === Parameters
#
# [*notification_email_to*] = [ "root@${domain}" ]
#   An array of emails to send notifications to
#
# [*notification_from*] = "keepalived@${domain}"
#   The source adress of notification messages
#
# [*smtp_server*] = 'localhost'
#   The SMTP server to use to send notifications.
#
# [*smtp_connect_timeout*] = '30'
#   The SMTP server to use to send notifications.
#
# [*router_id*] = $::hostname
#   The router_id identifies us on the network.
#
# === Variables
#
# [*$keepalived::variables::keepalived_conf*]
#   Path to keepalived.conf configuration file
#
# === Examples
#
#  class { keepalived: }
#
# === Authors
#
# Author Name <bruno.leon@unyonsys.com>
#
# === Copyright
#
# Copyright 2012 Bruno LEON, unless otherwise noted.
#
class keepalived (
  $notification_email_to   = [ "root@${domain}" ],
  $notification_email_from = "keepalived@${domain}",
  $smtp_server             = 'localhost',
  $smtp_connect_timeout    = '30',
  $router_id               = $::hostname,
) {

  Class[ "${module_name}::install" ] -> Class[ "${module_name}::config" ] ~> Class[ "${module_name}::service" ]

  include "${module_name}::variables"
  class { "${module_name}::install": }
  class { "${module_name}::config":
    notification_email_to   => $keepalived::notification_email_to,
    notification_email_from => $keepalived::notification_email_from,
    smtp_server             => $keepalived::smtp_server,
    smtp_connect_timeout    => $keepalived::smtp_connect_timeout,
    router_id               => $keepalived::router_id,
  }
  class { "${module_name}::service": }
}
