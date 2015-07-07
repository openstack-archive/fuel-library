#!/usr/bin/env ruby
require 'rubygems'
require 'json'
require 'hiera'

ENV['LANG'] = 'C'
$hiera = Hiera.new(:config => '/etc/hiera.yaml')

def ceph(args)
  stdout = `ceph -f json #{args}`
  return JSON.parse(stdout) if $?.exitstatus == 0
  puts "Error: exit code #{$?.exitstatus}"
  return false
end

def ready_ceph
  return false if !(ceph_health = ceph('health'))
  return true if ceph_health['overall_status'].include? 'HEALTH_OK'
  if ceph_health['overall_status'].include? 'HEALTH_ERR'
    puts "Ceph cluster health is in error!"
    return false
  end
  #Getting the pool size
  pool_size = $hiera.lookup('storage', false, {})['osd_pool_size'].to_i
  #Getting the number of ceph osds, which are in cluster and in up state
  return false if !(osd_stat = ceph('osd stat'))
  osds_up = osd_stat['num_up_osds']
  osds_in = osd_stat['num_in_osds']
  if (osds_up < pool_size) or (osds_in < pool_size)
    puts "OSDs in cluster less than pool size: Pool size #{pool_size} UP #{osds_up} IN #{osds_in}"
    return false
  end
  #Check whether every OSD wich is in state also and in up state
  return false if !(osd_dump = ceph('osd dump'))
  osd_dump['osds'].each do |osd_id|
    if ( osd_id['in'] == 1 and osd_id['up'] == 0 )
      puts "The osd.#{osd_id['osd']} is in bad state: instate #{osd_id['in']} upstate #{osd_id['up']} !"
      return false
    end
  end
  #Check whether every pg has correct state
  return false if !(pg_dump = ceph('pg dump_stuck inactive'))
  if !(pg_dump.empty?)
    puts "There are PGs which are not in active state!"
    return false
  end
  return true
end

# check if ceph cluster is ready
def wait_for_ready_ceph
  160.times do |try|
    puts "try #{try}"
    return if ready_ceph
    sleep 10
  end
  ceph_health = `ceph -s`
  raise "
Ceph is not ready yet!
Please check the status of ceph cluster manually.
http://ceph.com/docs/master/rados/operations/monitoring/

#{ceph_health}"
end

wait_for_ready_ceph
