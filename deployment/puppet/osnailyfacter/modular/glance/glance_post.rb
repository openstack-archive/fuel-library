require File.join File.dirname(__FILE__), '../test_common.rb'

PORT = 9292

ENV['OS_TENANT_NAME']="services"
ENV['OS_USERNAME']="glance"
ENV['OS_PASSWORD']="#{Settings.glance['user_password']}"
ENV['OS_AUTH_URL']="http://#{Settings.management_vip}:5000/v2.0"
ENV['OS_ENDPOINT_TYPE'] = "internalURL"

class GlancePostTest < Test::Unit::TestCase

  def test_glance_api_is_running
    assert TestCommon::Process.running?('/usr/bin/glance-api'), 'Glance API is not running!'
  end

  def test_glance_gistry_is_running
    assert TestCommon::Process.running?('/usr/bin/glance-registry'), 'Glance Registry is not running!'
  end

  def test_glance_public_url_accessible
    url = "http://#{TestCommon::Settings.public_vip}:#{PORT}"
    assert TestCommon::Network.url_accessible?(url), "Public Glance URL '#{url}' is not accessible!"
  end

  def test_glance_admin_url_accessible
    url = "http://#{TestCommon::Settings.management_vip}:#{PORT}"
    assert TestCommon::Network.url_accessible?(url), "Management Glance URL '#{url}' is not accessible!"
  end

  def test_keystone_endpoint_list_run
    cmd = 'glance image-list'
    assert TestCommon::Process.run_successful?(cmd), "Could not run '#{cmd}'!"
  end

end
