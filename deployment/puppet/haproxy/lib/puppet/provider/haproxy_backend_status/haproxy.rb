require 'open-uri'
require 'socket'
require 'timeout'

Puppet::Type.type(:haproxy_backend_status).provide(:haproxy) do
  desc 'Wait for HAProxy backend to become online'

  # get the raw csv value using one of the methods
  # retry if operations fails
  # @return [String]
  def csv
    @resource[:count].times do |n|
      begin
        csv = Timeout::timeout(@resource[:timeout]) do
          if @resource[:socket]
            debug "Get CSV from socket: '#{@resource[:socket]}'"
            get_csv_unix
          else
            debug "Get CSV from url: '#{@resource[:url]}'"
            get_csv_url
          end
        end
        return csv if csv
      rescue
        nil
      end
      debug "Could not get CSV. Retry: '#{n}'"
      sleep @resource[:step]
    end
    if @resource[:socket]
      fail "Could not get CSV from socket: '#{@resource[:socket]}'"
    else
      fail "Could not get CSV from url: '#{@resource[:url]}'"
    end
  end

  # return the parsed stats structure
  # @return [Hash<String => Symbol>]
  def stats
    return @stats if @stats
    stats = {}
    csv.split("\n").each do |line|
      next if line.start_with? '#'
      fields = line.split(',')
      name = fields[0]
      type = fields[1]
      status = fields[17]
      next unless name and type and status
      next unless type == 'BACKEND'
      stats.store name, status
    end
    @stats = stats
  end

  # reset mnemoization of stats
  def stats_reset
    @stats = nil
  end

  # get the current backend status value
  # @return [:up, :down, :absent, :present]
  def ensure
    debug 'Call: ensure'
    out = status
    debug get_haproxy_debug_report
    debug "Return: #{out}"
    out
  end

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

  # check if backend exists
  # @return [TrueClass, FalseClass]
  def exists?
    stats.key? @resource[:name]
  end

  # get backend status from stats structure
  # @return [:up, :down, :present, :absent]
  def status
    status = stats.fetch @resource[:name], nil
    debug "Got status: '#{status}'"
    return :absent unless status
    return :present if [:present, :absent].include? @resource[:ensure]
    return :up if status == 'UP'
    return :down if status == 'DOWN'
    :present
  end

  # get csv from HAProxy socket
  # @return [String, NilClass]
  def get_csv_unix
    csv = ''
    socket = @resource[:socket]
    begin
      UNIXSocket.open(socket) do |opened_socket|
        opened_socket.puts 'show stat'
        loop do
          line = opened_socket.gets
          break unless line
          csv << line
        end
      end
    rescue
      nil
    end
    return unless csv and not csv.empty?
    csv
  end

  # download csv from url
  # @return [String, NilClass]
  def get_csv_url
    begin
      url = open(@resource[:url])
      csv = url.read
    rescue
      nil
    end
    return unless csv and not csv.empty?
    csv
  end

  def get_haproxy_debug_report
    return unless stats.is_a? Hash and stats.any?
    max_backend_name_length = stats.keys.max_by { |k| k.length }.length
    report = "\n"
    report += "HAProxy Backends:\n"
    stats.each do |backend, status|
      report += "* #{backend.ljust max_backend_name_length} : #{status}\n"
    end
    report
  end

end
