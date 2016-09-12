class osnailyfacter::plugins::plugins_setup_repositories {

  notice('MODULAR: plugins/plugins_setup_repositories.pp')
  $override_configuration = hiera_hash(configuration, {})
  create_resources(override_resources, $override_configuration)

  $plugins = hiera('plugins')

  if $::osfamily == 'Debian' {
    include ::apt

    $repositories = generate_plugins_repos($plugins)

    if ! empty($repositories) {
      create_resources(apt::source, $repositories)
    }

  }

}
