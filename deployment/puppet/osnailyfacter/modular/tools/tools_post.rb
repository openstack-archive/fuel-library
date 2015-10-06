require File.join File.dirname(__FILE__), '../test_common.rb'

TOOLS = %w(
acpid
screen
tmux
man
htop
tcpdump
strace
atop
puppet-pull
)

class ToolsPostTest < Test::Unit::TestCase
  def self.create_tests
    TOOLS.each do |tool|
      method_name = "test_tool_#{tool}_present"
      define_method method_name do
        assert TestCommon::Process.command_present?(tool), "There is no '#{tool}' installed!"
      end
    end
  end
end

ToolsPostTest.create_tests
