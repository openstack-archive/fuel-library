notice('MODULAR: fuel_pkgs.pp')

$fuel_packages=['fuel-ha-utils','fuel-misc']
notify{"this is the place where ${fuel_packages} should be installed":}
#FIXME(algarendil): uncomment this when we switch to pkg-based stuff
#package {$fuel_packages: ensure => latest }

