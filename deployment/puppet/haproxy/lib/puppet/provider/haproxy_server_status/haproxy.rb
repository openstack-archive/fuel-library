require 'socket'
require 'timeout'
require 'net/http'
require 'uri'
require 'puppet/provider/haproxy'
require 'pry'


Puppet::Type.type(:haproxy_server_status).provide(:haproxy, :parent => Puppet::Provider::Haproxy) do
  desc 'Manage haproxy real servers'

  defaultfor :kernel => :linux

  def service_name
    @resource[:name].split('/')[0]
  end
  
  def server_name
    @resource[:name].split('/')[1]
  end

  # wait for backend status to change into specified value
  # @param value [:up, :down]

  def ensure=(value)
    debug "Call: ensure=(#{value})"
    debug "Waiting for HAProxy backend: '#{@resource[:name]}' to change its status to: '#{value}'"
    @resource[:count].times do
      stats_reset
      binding.pry
      if value == :maintenance
        socket = UNIXSocket.new(@resource[:control_socket])
        socket.puts("disable server #{service_name}/#{server_name}")
      elsif value == :up
        socket = UNIXSocket.new(@resource[:control_socket])
        socket.puts("enable server #{service_name}/#{server_name}")
      end
      if self.status == value
        debug get_haproxy_debug_report
        return true
      end
      sleep @resource[:step]
    end
    debug get_haproxy_debug_report
    fail "Timeout waiting for HAProxy backend: '#{@resource[:name]}' status to become: '#{value}' after #{@resource[:count] * @resource[:step]} seconds!"
  end

end
