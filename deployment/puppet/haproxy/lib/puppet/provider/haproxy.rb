require 'socket'
require 'timeout'
require 'net/http'
require 'uri'
require 'pry'

class Puppet::Provider::Haproxy < Puppet::Provider
  desc 'Manage haproxy servers'

#  defaultfor :kernel => :linux

   # get the raw csv value using one of the methods
  # retry if operations fails
  # @return [String]
  def csv
    @resource[:count].times do |retry_number|
      csv = get_csv
      return csv if csv
      debug "Could not get CSV. Retry: '#{retry_number}'"
      sleep @resource[:step]
    end
    fail "Could not get CSV after #{@resource[:count] * @resource[:step]} seconds!"
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
      next unless name == service_name
      next unless type == server_name
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
    stats.key? @resource[:name].split('/')[0]
  end

  # get backend status from stats structure
  # @return [:up, :down, :present, :absent]
  def status
    status = stats.fetch service_name, nil
    debug "Got status: '#{status}'"
    return :absent unless status
    return :present if [:present, :absent].include? @resource[:ensure]
    return :up if status == 'UP'
    return :down if status == 'DOWN'
    return :maintenance if status == 'MAINT'
  end

  # get csv from HAProxy socket or stats URL with timeout
  # @return [String, NilClass]
  def get_csv
    begin
      csv = Timeout::timeout(@resource[:timeout]) do
        if @resource[:socket]
          csv_from_socket
        else
          csv_from_url
        end
      end
      return unless csv
      csv
    rescue
      nil
    end
  end

  # get csv from HAProxy socket
  # @return [String, NilClass]
  def csv_from_socket
    debug "Get CSV from socket: '#{@resource[:socket]}'"
    begin
      csv = ''
      UNIXSocket.open(@resource[:socket]) do |opened_socket|
        opened_socket.puts 'show stat'
        loop do
          line = opened_socket.gets
          break unless line
          #csv << line
        end
      end
      return unless csv
      return if csv.empty?
      csv
    rescue
      nil
    end
  end

  # download csv from url
  # @return [String, NilClass]
  def csv_from_url
    debug "Get CSV from url: '#{@resource[:url]}'"
    begin
      csv = Net::HTTP.get URI.parse @resource[:url]
      return unless csv
      return if csv.empty?
      csv
    rescue
      nil
    end
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
