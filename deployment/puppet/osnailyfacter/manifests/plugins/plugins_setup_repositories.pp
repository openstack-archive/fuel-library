class osnailyfacter::plugins::plugins_setup_repositories {

  notice('MODULAR: plugins/plugins_setup_repositories.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  $plugins = hiera('plugins')

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  if $::osfamily == 'Debian' {
    include ::apt

    $repositories = generate_plugins_repos($plugins)

    if ! empty($repositories) {
      create_resources(apt::source, $repositories)
    }

  }

}
