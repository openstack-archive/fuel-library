class openstack::firewall::novachains()
{

firewallchain {'nova-api-INPUT:filter:IPv4':
ensure => present,
}

firewallchain {'nova-api-FORWARD:filter:IPv4':
ensure => present,
}

firewallchain {'nova-api-OUTPUT:filter:IPv4':
ensure => present,
}

firewallchain {'nova-api-local:filter:IPv4':
ensure => present,
}

firewallchain {'nova-filter-top:filter:IPv4':
ensure => present,
}


firewallchain {'nova-api-OUTPUT:nat:IPv4':
ensure => present,
}

firewallchain {'nova-api-POSTROUTING:nat:IPv4':
ensure => present,
}


firewallchain {'nova-api-PREROUTING:nat:IPv4':
ensure => present,
}

firewallchain {'nova-api-float-snat:nat:IPv4':
ensure => present,
}

firewallchain {'nova-api-snat:nat:IPv4':
ensure => present,
}

firewallchain {'nova-api-postrouting-bottom:nat:IPv4':
ensure => present,
}

}
