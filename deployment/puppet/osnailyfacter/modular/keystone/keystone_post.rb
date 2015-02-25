require File.join File.dirname(__FILE__), '../test_common.rb'

PUBLIC_PORT = 5000
ADMIN_PORT = 35357

# Keystone doen't have a user, so we'd have to use the admin token, or use
# another user like nova.
ENV['OS_TENANT_NAME']="services"
ENV['OS_USERNAME']="nova"
ENV['OS_PASSWORD']="#{Settings.nova['user_password']}"
ENV['OS_AUTH_URL']="http://#{Settings.management_vip}:#{PUBLIC_PORT}/v2.0"
ENV['OS_ENDPOINT_TYPE'] = "internalURL"

class KeystonePostTest < Test::Unit::TestCase

  def test_keystone_is_running
    assert TestCommon::Process.running?('/usr/bin/keystone-all'), 'Keystone is not running!'
  end

  def test_keystone_public_url_accessible
    url = "http://#{TestCommon::Settings.public_vip}:#{PUBLIC_PORT}"
    assert TestCommon::Network.url_accessible?(url), "Public Keystone URL '#{url}' is not accessible!"
  end

  def test_keystone_admin_url_accessible
    url = "http://#{TestCommon::Settings.management_vip}:#{ADMIN_PORT}"
    assert TestCommon::Network.url_accessible?(url), "Admin Keystone URL '#{url}' is not accessible!"
  end

  def test_keystone_endpoint_list_run
    cmd = 'keystone endpoint-list'
    assert TestCommon::Process.run_successful?(cmd), "Could not run '#{cmd}'!"
  end

  def test_openrc_file_present
    assert File.exist?('/root/openrc'), '/root/openrc is missing!'
  end

end
