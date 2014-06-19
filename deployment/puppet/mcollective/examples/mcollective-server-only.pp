$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

$mco_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress']

$mco_pskey = "unset"
$mco_vhost = "mcollective"
$mco_user = $::fuel_settings['mcollective']['user']
$mco_password = $::fuel_settings['mcollective']['password']
$mco_connector = "rabbitmq"

class { "mcollective::server":
    pskey    => $::mco_pskey,
    vhost    => $::mco_vhost,
    user     => $::mco_user,
    password => $::mco_password,
    host     => $::mco_host,
    stomp    => false,
}
