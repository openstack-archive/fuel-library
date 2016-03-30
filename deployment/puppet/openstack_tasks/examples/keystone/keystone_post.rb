require File.join File.dirname(__FILE__), '../test_common.rb'

PUBLIC_PORT = 5000
ADMIN_PORT = 35357

class KeystonePostTest < Test::Unit::TestCase

  def test_keystone_is_running
    assert TestCommon::Process.running?('/usr/sbin/apache2'), 'Keystone is not running!'
  end

  def test_keystone_public_url_accessible
    url = "https://#{TestCommon::Settings.public_vip}:#{PUBLIC_PORT}"
    assert TestCommon::Network.url_accessible?(url), "Public Keystone URL '#{url}' is not accessible!"
  end

  def test_keystone_admin_url_accessible
    url = "http://#{TestCommon::Settings.management_vip}:#{ADMIN_PORT}"
    assert TestCommon::Network.url_accessible?(url), "Admin Keystone URL '#{url}' is not accessible!"
  end

  def test_keystone_endpoint_list_run
    TestCommon::Cmd.openstack_auth
    cmd = 'keystone endpoint-list'
    assert TestCommon::Process.run_successful?(cmd), "Could not run '#{cmd}'!"
  end

  def test_root_openrc_file_present
    assert File.exist?('/root/openrc'), '/root/openrc is missing!'
  end

  def test_os_user_openrc_file_present
    assert File.exist?("#{TestCommon::Settings.operator_user_homedir}/openrc"), "#{TestCommon::Settings.operator_user_homedir}/openrc is missing!"
  end

  def test_svc_openrc_file_present
    assert File.exist?("#{TestCommon::Settings.service_user_homedir}/openrc"), "#{TestCommon::Settings.service_user_homedir}/openrc is missing!"
  end

end
