require File.join File.dirname(__FILE__), 'haproxy_post_common.rb'

def expected_backends
  return $expected_backends if $expected_backends
  backends = %w(
    nova-api-1
    nova-api-2
    nova-metadata-api
  )
  $expected_backends = backends
end

OpenstackHaproxyPostTest.create_tests
