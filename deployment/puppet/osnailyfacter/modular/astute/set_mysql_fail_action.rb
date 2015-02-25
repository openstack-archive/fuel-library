#!/usr/bin/env ruby
require 'rubygems'
require 'hiera'
require 'timeout'

RETRY_COUNT   = 5
RETRY_WAIT    = 1
RETRY_TIMEOUT = 10

def get_nodes
  hiera = Hiera.new(:config => '/etc/puppet/hiera.yaml')
  nodes_array = hiera.lookup 'nodes', [], {}
  raise 'Invalid nodes data!' unless nodes_array.is_a? Array
  nodes_array
end

def get_controller_nodes
  get_nodes.select {|n|
    ['controller', 'primary-controller'].include? n['role']
  }.size
end

def set_onfail_policy(operation_id, value)
  puts "Setting on-fail for op id '#{operation_id}' to: '#{value}'"
  RETRY_COUNT.times do |n|
    begin
      Timeout::timeout(RETRY_TIMEOUT) do
        system <<-doc
          cibadmin -M -X '<op id="#{operation_id}" on-fail="#{value}" />'
        doc
        return if $?.exitstatus == 0
      end
    rescue Timeout::Error
      nil
    end
    puts "Error! Retry: #{n + 1}"
    sleep RETRY_WAIT
  end
  fail "Could not set on-fail for op id '#{operation_id}' to: '#{value}'!"
end

def get_onfail_policy(operation_id)
  RETRY_COUNT.times do |n|
    begin
      Timeout::timeout(RETRY_TIMEOUT) do
        value = 'undefined'
        raw = `cibadmin -QA '//op[@id="#{operation_id}"]'`.chomp
        raw.split(' ').each do |part|
          if part =~ /^on-fail=/
            value = part.split('=')[1].gsub(/[^\w]/, '')
          end
        end
        return value if $?.exitstatus == 0
      end
    rescue Timeout::Error
      nil
    end
    puts "Error! Retry: #{n + 1}"
    sleep RETRY_WAIT
  end
  fail "Could not get on-fail for op id '#{operation_id}!"
end

##############

opid = 'p_mysql-monitor-60'

controller_nodes = get_controller_nodes
current_onfail_policy = get_onfail_policy(opid)

puts "Controller nodes found: '#{controller_nodes}'"

if controller_nodes > 2
  set_onfail_policy(opid, 'restart') unless current_onfail_policy == 'restart'
else
  set_onfail_policy(opid, 'ignore') unless current_onfail_policy == 'ignore'
end

puts "Current on-fail policy for op id '#{opid}' is: '#{get_onfail_policy(opid)}'"
exit 0
