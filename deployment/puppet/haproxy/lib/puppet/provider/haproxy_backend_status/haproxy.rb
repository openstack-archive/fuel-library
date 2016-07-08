require 'socket'
require 'timeout'
require 'net/http'
require 'uri'


Puppet::Type.type(:haproxy_backend_status).provide(:haproxy) do
  desc 'Wait for HAProxy backend to become online'

  defaultfor :kernel => :linux

  @service_name = @resource[:name]
  @server_name = 'BACKEND'
  # wait for backend status to change into specified value
  # @param value [:up, :down]
  def ensure=(value)
    debug "Call: ensure=(#{value})"
    debug "Waiting for HAProxy backend: '#{@resource[:name]}' to change its status to: '#{value}'"
    @resource[:count].times do
      stats_reset
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
