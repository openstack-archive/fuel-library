require 'test/unit'

def tool_present(tool)
  `which '#{tool}' 1>/dev/null 2>/dev/null`
  $?.exitstatus == 0
end

TOOLS = %w(
screen
tmux
man
htop
tcpdump
strace
atop
puppet-pull
haproxy-status
)

class ToolsPostTest < Test::Unit::TestCase
  def self.create_tests
    TOOLS.each do |tool|
      method_name = "test_tool_#{tool}_present"
      define_method method_name do
        assert tool_present(tool), "There is no '#{tool}' installed!"
      end
    end
  end
end

ToolsPostTest.create_tests
