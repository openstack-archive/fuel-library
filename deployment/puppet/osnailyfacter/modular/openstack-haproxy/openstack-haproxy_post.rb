require File.join File.dirname(__FILE__), '../test_common.rb'

def expected_backends
  return $expected_backends if $expected_backends
  backends = %w(
    Stats
    horizon
    keystone-1
    keystone-2
    nova-api
    nova-metadata-api
    cinder-api
    glance-api
    neutron
    glance-registry
    mysqld
    swift
    heat-api
    heat-api-cfn
    heat-api-cloudwatch
    nova-novncproxy
  )
  backends += %w(sahara) if TestCommon::Settings.sahara['enabled']
  backends += %w(murano murano_rabbitmq) if TestCommon::Settings.murano['enabled']
  $expected_backends = backends
end

class OpenstackHaproxyPostTest < Test::Unit::TestCase
  def self.create_tests
    expected_backends.each do |backend|
      method_name = "test_backend_#{backend}_present"
      define_method method_name do
        assert TestCommon::HAProxy.backend_present?(backend), "There is no '#{backend}' HAProxy backend!"
      end
    end
  end
end

OpenstackHaproxyPostTest.create_tests
