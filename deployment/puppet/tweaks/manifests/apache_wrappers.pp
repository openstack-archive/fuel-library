# Tweak Service httpd or apache2
class tweaks::apache_wrappers (
) {

  $service_name = $::osfamily ? {
    'RedHat' => 'httpd',
    'Debian' => 'apache2',
    default  => fail("Unsupported osfamily: ${::osfamily}"),
  }

  # we try a graceful restart but will fall back to a restart if graceful fails
  # as we have found that sometimes with mod_wsgi apache will crash on a
  # graceful restart - https://github.com/GrahamDumpleton/mod_wsgi/issues/81
  Service <| name == $service_name or title == $service_name |> {
    restart    => 'sleep 30 && apachectl graceful || apachectl restart',
    hasrestart => true,
  }
}
