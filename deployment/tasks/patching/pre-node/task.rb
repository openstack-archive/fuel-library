#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), '../lib/base')
require File.join(File.dirname(__FILE__), '../lib/service')
require File.join(File.dirname(__FILE__), '../lib/process')
require File.join(File.dirname(__FILE__), '../lib/mysql')
require File.join(File.dirname(__FILE__), '../lib/migration')

class PreNode
  include Base
  include Service
  include Process
  include MySQL
  include Migration

  def execute
    services = %r{nova|cinder|glance|keystone|neutron|sahara|murano|ceilometer|heat|swift|apache2|httpd}
    @dry_run = false
    remove_log
    stop_services_by_regexp services
    kill_pids_by_regexp services
    recreate_murano_database
  end

end

if __FILE__ == $0
  me = PreNode.new
  me.execute
end
