class osnailyfacter::fuel_pkgs::fuel_pkgs {

  notice('MODULAR: fuel_pkgs/fuel_pkgs.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  $deep_merge_package_name = $::osfamily ? {
    'RedHat' => 'rubygem-deep_merge',
    'Debian' => 'ruby-deep-merge',
  }

  $fuel_packages = [
    'fuel-ha-utils',
    'fuel-misc',
    $deep_merge_package_name
  ]

  ensure_packages($fuel_packages)

}
