Puppet::Type.type(:service_status).provide(:ruby) do
  desc 'Wait for custom service to become online'

  defaultfor :kernel => :linux

  # get the current custom service status value
  # @return [:online, :offline]
  def ensure
    debug 'Call: ensure'
    out = status
    debug "Return: #{out}"
    out
  end

  # wait for custom service to switch to needed state
  # @param value [:online, :offline]
  def ensure=(value)
    debug "Call: ensure=(#{value})"
    debug "Waiting for custome service: '#{@resource[:name]}' to change its status to: '#{value}'"
    @resource[:count].times do
      if status == value
        return true
      end
      sleep @resource[:step]
    end
    fail "Timeout waiting for custom service: '#{@resource[:name]}' to become: '#{value}' after #{@resource[:count] * @resource[:step]} seconds!"
  end

  # get custom service status
  # @return [:online, :offline]
  def status
    rv = system(@resource[:check_cmd])
    status = $?.exitstatus
    debug "Got status: '#{status}'"
    if status == @resource[:exitcode]
      :online
    else
      :offline
    end
  end

end
