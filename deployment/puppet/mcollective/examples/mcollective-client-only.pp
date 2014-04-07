$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

$mco_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress']

$mco_pskey = "unset"
$mco_vhost = "mcollective"
$mco_user = "mcollective"
$mco_password = "marionette"
$mco_connector = "rabbitmq"

class { "mcollective::client":
    pskey    => $::mco_pskey,
    vhost    => $::mco_vhost,
    user     => $::mco_user,
    password => $::mco_password,
    host     => $::mco_host,
    stomp    => false,
}
