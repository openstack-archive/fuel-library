# Tweak Service httpd or apache2
class tweaks::apache_wrappers (
) {

  Service <| name == $service_name or title == $service_name |> {
    restart    => 'apachectl restart',
    hasrestart => true,
  }
}
