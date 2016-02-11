require File.join File.dirname(__FILE__), 'haproxy_post_common.rb'

def expected_backends
  return $expected_backends if $expected_backends
  backends = %w(
    aodh
  )
  $expected_backends = backends
end

OpenstackHaproxyPostTest.create_tests
