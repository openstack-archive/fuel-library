class openstack::ironic (
  $rabbit_hosts        = false,
  $rabbit_userid       = 'guest',
  $rabbit_password     = false,
  $database_connection = 'sqlite:////var/lib/ironic/ovs.sqlite',
  $ironic_api          = false,
) {

  class { '::ironic':
    rabbit_hosts        => $rabbit_hosts,
    rabbit_userid       => $rabbit_userid,
    rabbit_password     => $rabbit_password,
    database_connection => $database_connection,
  }

  if $ironic_api {
   class { '::ironic::api':
     admin_password => 'test',
   }

   class {'::ironic::client':}
  }

}
