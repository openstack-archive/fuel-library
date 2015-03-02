require File.join File.dirname(__FILE__), '../pre_post_test_common.rb'

BACKEND = 'mysqld'

class DatabasePreTest < Test::Unit::TestCase
  def test_mysqld_haproxy_backend_present
    assert haproxy_backends.include?(BACKEND), "There is no '#{BACKEND}' HAProxy backend!"
  end
end
