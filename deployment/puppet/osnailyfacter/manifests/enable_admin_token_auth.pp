# Enable the admin_token_auth in the keystone paste.ini file
#
class osnailyfacter::enable_admin_token_auth {

  ini_subsetting { 'public_api/admin_token_auth':
    ensure     => 'present',
    path       => '/etc/keystone/keystone-paste.ini',
    section    => 'pipeline:public_api',
    setting    => 'pipeline',
    subsetting => 'admin_token_auth',
  }

  ini_subsetting { 'admin_api/admin_token_auth':
    ensure     => 'present',
    path       => '/etc/keystone/keystone-paste.ini',
    section    => 'pipeline:admin_api',
    setting    => 'pipeline',
    subsetting => 'admin_token_auth',
  }

  ini_subsetting { 'api_v3/admin_token_auth':
    ensure     => 'present',
    path       => '/etc/keystone/keystone-paste.ini',
    section    => 'pipeline:api_v3',
    setting    => 'pipeline',
    subsetting => 'admin_token_auth',
  }

  Package <| title == 'keystone' |> ->
  Ini_subsetting[
    'public_api/admin_token_auth',
    'admin_api/admin_token_auth',
    'api_v3/admin_token_auth'
  ] ~>
  Service <| title == 'keystone' or title == 'httpd' |>

}
