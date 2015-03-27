notice('MODULAR: fuel_pkgs.pp')

$fuel_packages=['fuel-ha-utils','fuel-misc']
notify{"this is the place where ${fuel_packages} should be installed":}
#FIXME(algarendil): remove this if when we switch to pkg-based stuff
if $::fuel_pkgs_exist == 'true'
{
 package {$fuel_packages: ensure => latest }
}

