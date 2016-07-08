require 'socket'
require 'timeout'
require 'net/http'
require 'uri'


Puppet::Type.type(:haproxy_server_status).provide(:haproxy) do
  desc 'Wait for HAProxy backend to become online'

  defaultfor :kernel => :linux

  @service_name = @resource[:name].split('/')[0]
  @server_name = @resource[:name].split('/')[1]


  # wait for backend status to change into specified value
  # @param value [:up, :down]

  def ensure=(value)
    debug "Call: ensure=(#{value})"
    debug "Waiting for HAProxy backend: '#{@resource[:name]}' to change its status to: '#{value}'"
    @resource[:count].times do
      stats_reset
      if value == :maintenance
        socket = UNIXSocket.new(@resource[:control_socket])
        socket.puts("disable server #{@service_name} #{@server_name}")
      elsif value == :up
        socket = UNIXSocket.new(@resource[:control_socket])
        socket.puts("enable server #{@service_name} #{@server_name}")
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
