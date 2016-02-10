require 'timeout'
require 'rexml/document'
require 'open3'

RETRY_COUNT   = 3
RETRY_WAIT    = 1
RETRY_TIMEOUT = 10

module Puppet::Parser::Functions
  newfunction(:corosync_nodes_in_cluster, :type => :rvalue, :doc => <<-EOS
  EOS
  ) do |args|
    RETRY_COUNT.times do |n|
      begin
        Timeout::timeout(RETRY_TIMEOUT) do
          nodes = []
          stdin, stdout, stderr, wait_thr = Open3.popen3('crm node status') rescue nil
          if wait_thr and wait_thr.value == 0
            nodes_xml = REXML::Document.new(stdout.read)
            nodes_xml.root.elements.each() do |node|
              nodes << {'id' => node.attribute('id').value, 'uname' => node.attribute('uname').value}
            end
            return nodes
          end
        end
      rescue Timeout::Error
        return []
      end
      sleep RETRY_WAIT
    end
    return []
  end
end
