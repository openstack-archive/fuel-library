require File.join File.dirname(__FILE__), '../test_common.rb'
include TestCommon

class DatabaseInstallPostTest < Test::Unit::TestCase

  def test_mysql_connection_keystone
    MySQL.pass = Settings.keystone['db_password']
    MySQL.user = 'keystone'
    MySQL.host = Settings.management_vip
    MySQL.port = 3306
    assert MySQL.connection?, 'Cannot connect to MySQL with Keystone auth!'
  end

  def test_mysql_connection_glance
    MySQL.pass = Settings.glance['db_password']
    MySQL.user = 'glance'
    MySQL.host = Settings.management_vip
    MySQL.port = 3306
    assert MySQL.connection?, 'Cannot connect to MySQL with Glance auth!'
  end

  def test_mysql_connection_nova
    MySQL.pass = Settings.nova['db_password']
    MySQL.user = 'nova'
    MySQL.host = Settings.management_vip
    MySQL.port = 3306
    assert MySQL.connection?, 'Cannot connect to MySQL with Nova auth!'
  end

  def test_mysql_connection_cinder
    MySQL.pass = Settings.cinder['db_password']
    MySQL.user = 'cinder'
    MySQL.host = Settings.management_vip
    MySQL.port = 3306
    assert MySQL.connection?, 'Cannot connect to MySQL with Cinder auth!'
  end

  def test_mysql_connection_neutron
    return unless Settings.use_neutron
    MySQL.pass = Settings.cinder['db_password']
    MySQL.user = 'cinder'
    MySQL.host = Settings.management_vip
    MySQL.port = 3306
    assert MySQL.connection?, 'Cannot connect to MySQL with Cinder auth!'
  end

end
