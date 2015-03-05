require File.join File.dirname(__FILE__), '../test_common.rb'
include TestCommon

PUBLIC_PORT = 5000
ADMIN_PORT = 35357

if Facts.osfamily == 'RedHat'
  PACKAGES = %w(
  openstack-keystone
  python-keystoneclient
  python-keystonemiddleware
  python-keystone
  )
end

class KeystonePostTest < Test::Unit::TestCase

  def test_packages_are_installed
    return unless PACKAGES
    PACKAGES.each do |package|
      assert Package.is_installed?(package), "Package '#{package}' is not installed!"
    end
  end

  def test_keystone_is_running
    assert PS.running?('/usr/bin/keystone-all'), 'Keystone is not running!'
  end

  def test_keystone_public_url_accessible
    url = "http://#{Settings.public_vip}:#{PUBLIC_PORT}"
    assert Net.url_accessible?(url), "Public Keystone URL '#{url}' is not accessible!"
  end

  def test_keystone_admin_url_accessible
    url = "http://#{Settings.management_vip}:#{ADMIN_PORT}"
    assert Net.url_accessible?(url), "Admin Keystone URL '#{url}' is not accessible!"
  end

  def test_keystone_endpoint_list_run
    cmd = 'source /root/openrc && keystone endpoint-list'
    assert PS.run_successful?(cmd), "Could not run '#{cmd}'!"
  end

  def test_openrc_file_present
    assert File.exist?('/root/openrc'), '/root/openrc is missing!'
  end

end
