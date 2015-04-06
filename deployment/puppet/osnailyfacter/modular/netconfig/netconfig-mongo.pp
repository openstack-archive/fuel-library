notice('MODULAR: netconfig-mongo.pp')

$gateway=hiera('master_ip')

l23network::l3::defaultroute { $gateway: }

