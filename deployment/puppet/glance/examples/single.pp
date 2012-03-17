
node glance {
  # set up glance server
  class { 'glance::api':
    swift_store_user => 'foo_user',
    swift_store_key => 'foo_pass',
  }

  class { 'glance::registry': }

}

node default {
  fail("could not find a matching node entry for ${clientcert}")
}
