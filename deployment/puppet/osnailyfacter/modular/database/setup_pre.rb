require File.join File.dirname(__FILE__), '../test_common.rb'
include TestCommon

class DatabaseSetupPreTest < Test::Unit::TestCase

  def test_mysql_connection_without_auth
    MySQL.no_auth
    assert MySQL.connection?, 'Cannot connect to MySQL without auth!'
  end

end
