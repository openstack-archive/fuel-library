class murano::apps (
    $primary_controller = true,
  ) {
    if $primary_controller {
        murano::application_package{ 'io.murano.apps.PostgreSql': }
        murano::application_package{ 'io.murano.apps.apache.Apache': }
        murano::application_package{ 'io.murano.apps.apache.Tomcat': }
        murano::application_package{ 'io.murano.apps.linux.Telnet': }
        murano::application_package{ 'io.murano.windows.ActiveDirectory': }
    }
  }