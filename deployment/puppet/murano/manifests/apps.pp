class murano::apps (
    $primary_controller = true,
  ) {
    package { 'murano-apps':
      ensure => installed,
      name   => $::murano::params::murano_apps_package_name,
    }

    if $primary_controller {
        murano::application_package { 'io.murano.apps.PostgreSql':
            package_category => 'Databases',
        }

        murano::application_package { 'io.murano.apps.apache.Apache':
            package_category => 'Web',
        }

        murano::application_package { 'io.murano.apps.apache.Tomcat':
            package_category => 'Web',
        }

        murano::application_package { 'io.murano.apps.linux.Telnet':
            package_category => 'Application Servers',
        }

        murano::application_package { 'io.murano.windows.ActiveDirectory':
            package_category => 'Microsoft Services',
        }

        Package<| title == 'murano-apps'|> -> Murano::Application_package<| mandatory == false |>
    }
  }
