#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'socket'
require 'timeout'
require 'net/http'
require 'uri'
require 'yaml'

class HaproxyStatus

  DEFAULT_STATS_URL = 'http://127.0.0.1:10000?;csv'
  DEFAULT_STATS_SOCKET = '/var/lib/haproxy/stats'

  TIMEOUT = 10
  STEP = 3
  COUNT = 30
  CONFIG_FILE = '/etc/haproxy-status.yaml'
  CSV_HEADER = 'pxname,svname,qcur,qmax,scur,smax,slim,stot,bin,bout,dreq,dresp,ereq,econ,eresp,wretr,wredis,status,weight,act,bck,chkfail,chkdown,lastchg,downtime,qlimit,pid,iid,sid,throttle,lbtot,tracked,type,rate,rate_lim,rate_max,check_status,check_code,check_duration,hrsp_1xx,hrsp_2xx,hrsp_3xx,hrsp_4xx,hrsp_5xx,hrsp_other,hanafail,req_rate,req_rate_max,req_tot,cli_abrt,srv_abrt,comp_in,comp_out,comp_byp,comp_rsp,lastsess,last_chk,last_agt,qtime,ctime,rtime,ttime'

  attr_writer :options

  # Try to load the config file
  # @return [Hash]
  def config
    begin
      config = YAML.load_file CONFIG_FILE
      return {} unless config.is_a? Hash
      config
    rescue
      {}
    end
  end

  # Get the remote HAProxy URL
  # @return [String]
  def stats_url
    config['url'] || DEFAULT_STATS_URL
  end

  # Get the local HAProxy socket
  # @return [String]
  def stats_socket
    config['socket'] || DEFAULT_STATS_SOCKET
  end

  # Parse the command line options and return the options structure.
  # @return [Hash]
  def options
    return @options if @options
    @options = {}
    OptionParser.new do |opts|
      opts.banner = 'Usage: haproxy-status [options]'
      opts.on('-d', '--debug', 'Enable debug messages') do
        @options[:debug] = true
      end
      opts.on('-w', '--remote', "Try to get the stats from the URL: '#{stats_url}' instead of the local Unix socket: '#{stats_socket}'") do
        @options[:remote] = true
      end
      opts.on('-s', '--socket SOCKET', "Use this Unix socket to get the stats from instead of the: '#{stats_socket}'") do |value|
        @options[:socket] = value
      end
      opts.on('-u', '--url URL', "Use this URL to get the stats from instead of the: '#{stats_url}'") do |value|
        @options[:url] = value
      end
      opts.on('-n', '--name REGEXP') do |value|
        @options[:name_filter] = value
      end
      opts.on('-a', '--status STATUS') do |value|
        @options[:status_filter] = value
      end
      opts.on('-b', '--backends', 'Show only backend statuses without the individual servers') do
        @options[:only_backends] = true
      end
      opts.on('-t', '--timeout SECONDS', 'A single get CSV attempt timeout') do |value|
        @options[:timeout] = value.to_i.abs
        @options[:timeout] = 1 if @options[:timeout] == 0
      end
      opts.on('-c', '--count NUMBER', 'Get CSV retry count') do |value|
        @options[:count] = value.to_i.abs
        @options[:count] = 1 if @options[:count] == 0
      end
      opts.on('-i', '--sleep SECONDS', 'Get CSV retry sleep') do |value|
        @options[:step] = value.to_i.abs
        @options[:step] = 1 if @options[:step] == 0
      end
      opts.on('-N', '--no-color', "Don't use colors") do
        @options[:no_color] = true
      end
      opts.on('-r', '--rate', 'Show session rate') do
        @options[:rate] = true
      end
    end.parse!
    @options[:timeout] = TIMEOUT unless @options[:timeout]
    @options[:step] = STEP unless @options[:step]
    @options[:count] = COUNT unless @options[:count]
    @options[:socket] = stats_socket unless @options[:socket]
    @options[:url] = stats_url unless @options[:url]
    @options
  end

  # Show the debug message
  # @param [String] message
  def debug(message)
    puts message if options[:debug]
  end

  # Show the error message and exit with the error code.
  # @param [String] message
  def error(message)
    puts "ERROR: #{message}"
    exit(1)
  end

  # Get the CSV from the HAProxy socket or from the stats URL with a timeout.
  # @return [String, NilClass]
  def get_csv
    begin
      csv = Timeout::timeout(options[:timeout]) do
        if File.socket? options[:socket] and not options[:remote]
          csv_from_socket
        else
          csv_from_url
        end
      end
      return unless csv
      csv
    rescue => exception
      debug "Error getting the CSV: #{exception}"
      nil
    end
  end

  # Get CSV from the HAProxy socket.
  # @return [String, NilClass]
  def csv_from_socket
    debug "Get CSV from the socket: '#{options[:socket]}'"
    begin
      csv = ''
      UNIXSocket.open(options[:socket]) do |opened_socket|
        opened_socket.puts 'show stat'
        loop do
          line = opened_socket.gets
          break unless line
          csv << line
        end
      end
      return unless csv
      return if csv.empty?
      csv
    rescue => exception
      debug "Error getting HAProxy stats from the socket: '#{options[:socket]}': #{exception}"
      nil
    end
  end

  # Get CSV from the HAProxy stats URL.
  # @return [String, NilClass]
  def csv_from_url
    debug "Get CSV from the URL: '#{options[:url]}'"
    begin
      uri = URI.parse options[:url]
      fail 'URL is not and HTTP/HTTPS url!' unless uri.is_a? URI::HTTP or uri.is_a? URI::HTTPS
      csv = Net::HTTP.get uri
      return unless csv
      return if csv.empty?
      csv
    rescue => exception
      debug "Error getting HAProxy stats from the URL: '#{options[:url]}': #{exception}"
      nil
    end
  end

  # Get the raw CSV value using one of the methods.
  # Retries if operations fails.
  # @return [String]
  def csv
    options[:count].times do |retry_number|
      csv = get_csv
      return csv if csv
      debug "Could not get the CSV data. Retry: #{retry_number + 1}"
      sleep options[:step]
    end
    fail "Could not get the CSV after: #{options[:count]} retries!"
  end

  # Parse the CSV into an array of records
  # @return [Array<Hash>]
  def stats
    return @stats if @stats
    stats = []
    csv.split("\n").each do |line|
      next if line.start_with? '#'
      record = {}
      fields = line.split(',')
      CSV_HEADER.split(',').each_with_index do |column, number|
        record[column] = fields[number]
      end
      next unless record['pxname'] and record['svname'] and record['status']
      stats << record
    end
    @stats = stats
  end

  # Set line color to red
  # @param [String] message
  # @return [String]
  def red(message)
    "\033[31m#{message}\033[0m"
  end

  # Set line color to green
  # @param [String] message
  # @return [String]
  def green(message)
    "\033[32m#{message}\033[0m"
  end

  # Prepare the report text
  # @return [String]
  def report
    fail 'The HAProxy stats are empty!' unless stats.any?

    max_name_length = 0
    stats.each do |record|
      next unless record['pxname']
      name_length = record['pxname'].length
      max_name_length = name_length if name_length > max_name_length
    end

    report = ''
    stats.each do |record|
      next if record['svname'].to_s == 'FRONTEND'

      if options[:only_backends]
        next if record['svname'].to_s != 'BACKEND'
      end

      if options[:name_filter]
        next unless Regexp.new(options[:name_filter].to_s) =~ record['pxname'].to_s
      end

      if options[:status_filter]
        next unless record['status'].to_s.downcase == options[:status_filter].to_s.downcase
      end

      line = ''
      line += record['pxname'].to_s.ljust max_name_length + 1
      line += record['svname'].to_s.ljust 15
      status = record['status'].to_s
      status += "/#{record['check_status']}" if record['check_status'] != ''
      line += "Status: #{status}".ljust 20

      if options[:rate]
        line += "Sessions: #{record['scur'].to_s}".ljust 15
        line += "Rate: #{record['rate'].to_s}".ljust 10
      end

      line += "Check: #{record['last_chk']}" if record['last_chk'] != ''

      line += "\n"

      unless options[:no_color]
        if record['status'].to_s == 'UP'
          line = green line
        elsif record['status'].to_s == 'DOWN'
          line = red line
        end
      end

      report += line
    end
    report
  end

  # Reset memoization of stats.
  def stats_reset
    @stats = nil
  end

  # The main function.
  def main
    begin
      print report
    rescue => exception
      error exception
    end
  end

end

if $0 == __FILE__
  HaproxyStatus.new.main
end
