class murano::apps (
    $primary_controller = true,
  ) {
    package { 'murano-apps':
      ensure => installed,
      name   => $::murano::params::murano_apps_package_name,
    }

    if $primary_controller {
        murano::application_package { 'io.murano.databases.PostgreSql':
            package_category => 'Databases',
        }

        murano::application_package { 'io.murano.databases.MySql':
            package_category => 'Databases',
        }

        murano::application_package { 'io.murano.databases.SqlDatabase':
            package_category => 'Databases',
        }

        murano::application_package { 'io.murano.apps.apache.ApacheHttpServer':
            package_category => 'Web',
        }

        murano::application_package { 'io.murano.apps.apache.Tomcat':
            package_category => 'Web',
        }

        murano::application_package { 'io.murano.apps.WordPress':
            package_category => 'Application Servers',
        }

        murano::application_package { 'io.murano.apps.ZabbixAgent':
            package_category => 'Application Servers',
        }

        murano::application_package { 'io.murano.apps.ZabbixServer':
            package_category => 'Application Servers',
        }

        Package<| title == 'murano-apps'|> -> Murano::Application_package<| mandatory == false |>
    }
  }
