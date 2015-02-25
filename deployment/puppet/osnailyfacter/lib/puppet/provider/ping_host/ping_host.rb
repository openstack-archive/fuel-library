require 'timeout'

Puppet::Type.type(:ping_host).provide(:ping_host) do
  desc  'Ping a host until in becomes online'

  commands :ping => 'ping'

  # check if the host is online
  # @return [:up,:down]
  def status
    begin
      Timeout::timeout(5) do
        ping '-q', '-c', '1', '-W', '3', @resource[:name]
      end
    rescue Timeout::Error, Puppet::ExecutionFailure
      return :down
    end
    :up
  end

  # get the host status value
  # @return [:up, :down]
  def ensure
    debug "Call 'ensure' on host '#{@resource[:name]}'"
    out = status
    debug "Return: #{out}"
    out
  end

  # wait for host status to change into specified value
  # @param value [:up, :down]
  def ensure=(value)
    debug "Waiting for host '#{@resource[:name]}' to change status to '#{value}'"
    @resource[:count].times do
      return if status == value
      sleep @resource[:step]
    end
    fail "Timeout waiting for host '#{@resource[:name]}' status to become '#{value}' after #{@resource[:count] * @resource[:step]} seconds!"
  end

end
