class osnailyfacter::netconfig::connectivity_tests {

  notice('MODULAR: netconfig/connectivity_tests.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }
  # Pull the list of repos from hiera
  $repo_setup = hiera('repo_setup')
  # test that the repos are accessible
  url_available($repo_setup['repos'])

}
