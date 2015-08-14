# Tweak Service httpd or apache2
class tweaks::apache_wrappers (
) {

  $service_name = $::osfamily ? {
    'RedHat' => 'httpd',
    'Debian' => 'apache2',
    default  => fail("Unsupported osfamily: ${::osfamily}"),
  }

  Service <| name == $service_name or title == $service_name |> {
    restart    => 'apachectl graceful',
    hasrestart => true,
  }
}
