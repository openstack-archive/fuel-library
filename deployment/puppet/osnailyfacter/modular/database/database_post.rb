require File.join File.dirname(__FILE__), '../pre_post_test_common.rb'

BACKEND = 'mysqld'
PROCESS = 'mysqld_safe'

class DatabasePostTest < Test::Unit::TestCase

  def test_mysqld_safe_is_running
    assert process_running?(PROCESS), "Process '#{PROCESS}' is not running!"
  end

  def test_mysqld_haproxy_backend_up
    assert haproxy_backend_up?(BACKEND), "HAProxy backend '#{BACKEND}' is not up!"
  end

end
