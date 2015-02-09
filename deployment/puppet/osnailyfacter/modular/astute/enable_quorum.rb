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

def set_quorum_policy(value)
  puts "Setting no-quorum-policy to: '#{value}'"
  RETRY_COUNT.times do |n|
    begin
      Timeout::timeout(RETRY_TIMEOUT) do
        system "crm_attribute --verbose --type crm_config --name no-quorum-policy --update #{value}"
        return if $?.exitstatus == 0
      end
    rescue Timeout::Error
      nil
    end
    puts "Error! Retry: #{n + 1}"
    sleep RETRY_WAIT
  end
  fail "Could not set no-quorum-policy to: '#{value}'!"
end

def get_quorum_policy
  RETRY_COUNT.times do |n|
    begin
      Timeout::timeout(RETRY_TIMEOUT) do
        policy = `crm_attribute --type crm_config --name no-quorum-policy --query --quiet`.chomp
        return policy if $?.exitstatus == 0
      end
    rescue Timeout::Error
      nil
    end
    puts "Error! Retry: #{n + 1}"
    sleep RETRY_WAIT
  end
  fail "Could not get no-quorum-policy!"
end

##############

controller_nodes = get_controller_nodes

puts "Controller nodes found: '#{controller_nodes}'"

if controller_nodes > 2
  set_quorum_policy 'stop'
else
  set_quorum_policy 'ignore'
end

puts "Current no-quorum-policy is: '#{get_quorum_policy}'"
