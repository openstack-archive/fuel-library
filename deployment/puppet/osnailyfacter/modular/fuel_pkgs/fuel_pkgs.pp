notice('MODULAR: fuel_pkgs.pp')

$fuel_packages = [
  'fuel-ha-utils',
  'fuel-misc',
]

package { $fuel_packages :
  ensure => 'latest',
}
