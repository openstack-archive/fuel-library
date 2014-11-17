#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), '../lib/base')
require File.join(File.dirname(__FILE__), '../lib/service')
require File.join(File.dirname(__FILE__), '../lib/process')

class Task
  include Base
  include Service
  include Process

  def execute
    @dry_run = false
    services = %r{nova|cinder|glance|keystone|neutron|sahara|murano|ceilometer|heat|swift|apache2|httpd}
    stop_services_by_regexp services
    kill_pids_by_regexp services
  end

end

if __FILE__ == $0
  me = Task.new
  me.execute
end
