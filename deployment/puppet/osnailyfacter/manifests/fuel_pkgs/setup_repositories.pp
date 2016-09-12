class osnailyfacter::fuel_pkgs::setup_repositories {

  notice('MODULAR: fuel_pkgs/setup_repositories.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  $repo_setup_hash = hiera_hash('repo_setup', {})
  $repos      = $repo_setup_hash['repos']
  $repo_type  = pick($repo_setup_hash['repo_type'], 'fuel')

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  class { '::osnailyfacter::package_pins':
    repo_type    => $repo_type,
    pin_haproxy  => $repo_setup_hash['pin_haproxy'],
    pin_rabbitmq => $repo_setup_hash['pin_rabbitmq'],
    pin_ceph     => $repo_setup_hash['pin_ceph'],
    pin_priority => '2000',
  }

  if $::osfamily == 'Debian' {
    include ::apt

    $repositories = generate_apt_sources($repos)
    $pins         = generate_apt_pins($repos)

    if ! empty($repositories) {
      create_resources(apt::source, $repositories)
    }

    if ! empty($pins) {
      create_resources(apt::pin, $pins)
    }

    Apt::Conf {
      notify_update => false,
      priority      => '02',
    }

    apt::conf { 'allow-unathenticated':
      content => 'APT::Get::AllowUnauthenticated 0;',
    }

    apt::conf { 'install-recommends':
      content => 'APT::Install-Recommends "false";',
    }

    apt::conf { 'install-suggests':
      content => 'APT::Install-Suggests "false";',
    }

    Apt::Source<||> ~> Exec<| title == 'apt_update' |>
    Exec<| title == 'apt_update' |> -> Package<||>
  }

}
