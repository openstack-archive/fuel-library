require File.join File.dirname(__FILE__), '../test_common.rb'

RABBITMQ_USER="rabbitmq"

class RabbitMQPostTest < Test::Unit::TestCase

  def test_rabbitmq_is_running
    assert TestCommon::Process.running?('/usr/sbin/rabbitmq-server'), 'RabbitMQ is not running!'
  end

  def test_rabbitmq_running_as_rabbitmq_user
    cmd = 'ps haxo user,cmd | egrep -v "su |grep "| egrep "rabbitmq|beam|epmd" | egrep -v "^' RABBITMQ_USER '"'
    assert TestCommon::Process.run_successful?(cmd), "'#{cmd}' returns processes not running as #{RABBITMQ_USER}'"
  end

end
