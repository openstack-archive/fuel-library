require 'hiera'
require 'test/unit'
require 'open-uri'
require 'timeout'
require 'facter'
require 'socket'

module TestCommon
  module Cmd
    # Run a shell command and return stdout and return code as an array
    # @param command [String] the command to run
    # @return [Array<String,Numeric>] Stdout and return code
    def self.run(command)
      out = `#{command}`
      code = $?.exitstatus
      [out, code]
    end

    # set the OpenStack CLI auth data
    def self.openstack_auth
      ENV['LC_ALL']           = 'C'
      ENV['OS_NO_CACHE']      = 'true'
      ENV['OS_TENANT_NAME']   = TestCommon::Settings.access['tenant']
      ENV['OS_USERNAME']      = TestCommon::Settings.access['user']
      ENV['OS_PASSWORD']      = TestCommon::Settings.access['password']
      ENV['OS_AUTH_URL']      = "http://#{TestCommon::Settings.management_vip}:5000/v2.0"
      ENV['OS_AUTH_STRATEGY'] = 'keystone'
      ENV['OS_REGION_NAME']   = 'RegionOne'
      ENV['OS_ENDPOINT_TYPE'] = 'internalURL'
    end

    # run the openstack cli command with auth
    # and parse the results into a structure
    # @return [Array<Hash>]
    def self.openstack_cli(command)
      openstack_auth
      out, code = run command
      return [nil, code] unless code == 0
      headers = nil
      data = []
      out.split("\n").each do |line|
        next unless line.start_with? '|'
        columns = line.split('|')
        next unless columns.length > 2
        columns = columns[1..-2].map do |column|
          column.chomp.strip
        end
        unless headers
          headers = columns
          next
        end
        record = {}
        field_number = 0
        columns.each do |column|
          header = headers[field_number]
          next unless header
          record[header] = column
          field_number += 1
        end
        data << record if record.any?
      end
      data
    end

  end

  module Settings
    # get a Hiera class instance
    # @return [Hiera]
    def self.hiera
      return @hiera if @hiera
      @hiera = Hiera.new(:config => '/etc/puppet/hiera.yaml')
    end

    # lookup a value using the Hiera class
    # @param key [String,Symbol] a value to look for
    # @return [String,Array,Hash,nil] found value or nil if not found
    def self.lookup(key, default=nil)
      key = key.to_s
      key = 'rabbit_hash' if key == 'rabbit'
      @keys = {} unless @keys
      return @keys[key] if @keys[key]
      @keys[key] = hiera.lookup key, default, {}
    end

    # access lookup values as methods
    def self.method_missing(key)
      lookup key
    end

    # access lookup methods as indices
    def self.[](key)
      lookup key
    end

    # reset mnemoization
    def self.reset
      @hiera = nil
      @keys = nil
    end
  end

  module HAProxy
    # get the URL of HAProxy stats page
    # @return [String] the stats url
    def self.stats_url
      ip = Settings.management_vip
      ip = Settings.controller_node_address unless ip
      raise 'Could not get internal address!' unless ip
      port = 10000
      "http://#{ip}:#{port}/;csv"
    end

    # read the CSV from the Stats URL
    # @return [String] csv data
    def self.csv
      return @csv if @csv
      begin
        url = open(stats_url)
        csv = url.read
      rescue
        nil
      end
      return nil unless csv and not csv.empty?
      @csv = csv
    end

    # parse the csv data to the backends and their statuses
    # 'backend_name' => 'UP/DOWN'
    # @return [Hash<String => String>] the backends structure
    def self.backends
      return @backends if @backends
      raise 'Could not get CSV from HAProxy stats!' unless csv
      backends = {}
      csv.split("\n").each do |line|
        next if line.start_with? '#'
        next unless line.include? 'BACKEND'
        fields = line.split(',')
        backend = fields[0]
        status = fields[17]
        backends[backend] = status
      end
      @backends = backends
    end

    # check if the backend is present
    # @param backend [String] the backend name
    # @return [true,false]
    def self.backend_present?(backend)
      backends.keys.include? backend
    end

    # check if the backend is online
    # @param backend [String] the backend name
    # @return [true,false]
    def self.backend_up?(backend)
      backends[backend] == 'UP'
    end

    # reset mnemoization
    def self.reset
      @csv = nil
      @backends = nil
    end
  end

  module Process

    # try to run the command and return true if the run was successful
    # @param cmd [String] the command to run
    # @return [true,false]
    def self.run_successful?(cmd)
      out = TestCommon::Cmd.run cmd
      out.last == 0
    end

    # try to run find if the command executable is installed
    # @param cmd [String] the command to run
    # @return [true,false]
    def self.command_present?(command)
      run_successful? "which '#{command}' 1>/dev/null 2>/dev/null"
    end

    # use the 'ps' to get the list of all running processes
    # @return [Array<String>] the list of running commands
    def self.list
      return @process_list if @process_list
      @process_list = []
      ps = TestCommon::Cmd.run 'ps haxo cmd'
      ps.first.split("\n").each do |cmd|
        @process_list << cmd
      end
      @process_list
    end

    # check if there is a running command which
    # command line contains this string
    # @param process [String] look for this string in the list
    # @return [true,false]
    def self.running?(process)
      not list.find { |cmd| cmd.include? process }.nil?
    end

    # use the 'ps' tool to build the process tree
    # using pids and ppids of the processes
    # and the pid as the hash key
    # @return [Hash<Numeric => Hash>]
    def self.tree
      return @process_tree if @process_tree
      @process_tree = {}
      ps = TestCommon::Cmd.run 'ps haxo pid,ppid,cmd'
      ps.first.split("\n").each do |p|
        f = p.split
        pid = f.shift.to_i
        ppid = f.shift.to_i
        cmd = f.join ' '

        # create entry for this pid if not present
        @process_tree[pid] = {
            :children => []
        } unless @process_tree.key? pid

        # fill this entry
        @process_tree[pid][:ppid] = ppid
        @process_tree[pid][:pid] = pid
        @process_tree[pid][:cmd] = cmd

        unless ppid == 0
          # create entry for parent process if not present
          @process_tree[ppid] = {
              :children => [],
              :cmd => '',
          } unless @process_tree.key? ppid

          # fill parent's children
          @process_tree[ppid][:children] << pid
        end
      end
      @process_tree
    end

    # reset mnemoization
    def self.reset
      @process_tree = nil
      @process_list = nil
    end
  end

  module MySQL
    @pass = nil
    @user = nil
    @host = nil
    @port = nil
    @db = nil
    @options = '--raw --skip-column-names --batch'

    # turn off the MySQL auth and use the saved credentials if any
    def self.no_auth
      @pass = nil
      @user = nil
      @host = nil
      @port = nil
      @db = nil
    end

    def self.pass=(pass)
      @pass = pass
    end

    def self.pass
      @pass
    end

    def self.user=(user)
      @user = user
    end

    def self.user
      @user
    end

    def self.host=(host)
      @host = host
    end

    def self.host
      @host
    end

    def self.port=(port)
      @port = port
    end

    def self.port
      @port
    end

    def self.db
      @db
    end

    def self.db=(db)
      @db = db
    end

    def self.options=(options)
      @options = options
    end

    def self.options
      @options
    end

    # execute the mysql query using the 'mysql' command
    # return the array of the output and the exit code
    # @param query [String] the query to run
    # @return [Array<String, Numeric>] command output
    def self.query(query)
      query = query.gsub %q('), %q(")
      command = %Q(mysql #{options} --execute='#{query}')
      command += %Q( --host='#{host}') if host
      command += %Q( --user='#{user}') if user
      command += %Q( --password='#{pass}') if pass
      command += %Q( --port='#{port}') if port
      command += %Q( --database='#{db}') if db
      TestCommon::Cmd.run command
    end

    # check if mysql can connect ot the server
    # @return [true,false]
    def self.connection?
      result = query 'show databases'
      result.last == 0
    end

    # get the list of databases on the server
    # @return [Array<String>] the list of database names
    def self.databases
      return @databases if @databases
      out, code = query 'show databases'
      return unless code == 0
      @databases = []
      out.split("\n").each do |db|
        @databases << db
      end
      @databases
    end

    # check is the database is present on the server
    # @param database [String] the database name
    # @return [true,false]
    def self.database_exists?(database)
      return unless databases
      databases.include?(database)
    end

    # reset mnemoization
    def self.reset
      @databases = nil
      no_auth
    end

  end

  module Pacemaker
    # check if pacemaker is online
    # @return [true,false]
    def self.online?
      begin
        out = Timeout::timeout(5) do
          TestCommon::Cmd.run 'cibadmin -Q'
        end
      rescue
        return false
      end
      out.last == 0
    end

    # get the list of pacemaker primitives
    # @return [Array<String>] the list of primitive names
    def self.primitives
      begin
        out = Timeout::timeout(5) do
          TestCommon::Cmd.run 'crm_resource -l'
        end
      rescue
        return
      end
      return unless out.last == 0
      primitives = []
      out.first.split("\n").each do |line|
        primitives << line.split(':').first
      end
      primitives
    end

    # remove prefix from primitive name
    # @param primitive [String] primitive name
    # @return [String] primitive name without prefix
    def self.clean_primitive_name(primitive)
      primitive = primitive.gsub /^clone_/, ''
      primitive = primitive.gsub /^master_/, ''
      primitive
    end

    # check if the primitive is present in paceamaker
    # @param primitive [String] primitive name
    # @return [true,false]
    def self.primitive_present?(primitive)
      primitive = clean_primitive_name primitive
      primitives.include? primitive
    end

    # check if the pacemaker primitive is started
    # at least on a single cluster node
    # @param primitive [String] primitive name
    # @return [true,false]
    def self.primitive_started?(primitive)
      primitive = clean_primitive_name primitive
      begin
        out = TestCommon::Cmd.run "crm_resource -r #{primitive} -W 2>&1"
      rescue
        return
      end
      return true if out.first.include? 'is running on'
      return false if out.first.include? 'is NOT running'
      nil
    end

    # reset mnemoization
    def self.reset
      nil
    end
  end

  module Facts
    # use the Puppet's Facter to lookup a value
    # @param fact [String,Symbol] the fact's name
    def self.value(fact)
      @facts = {} unless @facts
      fact = fact.to_s
      return @facts[fact] if @facts[fact]
      @facts[fact] = Facter.value fact
      @facts[fact]
    end

    # access using indices
    def self.[](fact)
      value fact
    end

    # access using method names
    def self.method_missing(fact)
      value fact
    end

    # reset mnemoization
    def self.reset
      @facts = nil
    end
  end

  module Package
    # obtain the list of rpm packages
    # using the 'rpm' tool
    # @returns [String] packages
    def self.get_rpm_packages
      out = TestCommon::Cmd.run "rpm -qa --queryformat '%{NAME}|%{VERSION}-%{RELEASE}\n'"
      out.first
    end

    # obtain the list of deb packages
    # using the 'dpkg-query' tool
    # @returns [String] packages
    def self.get_deb_packages
      out = TestCommon::Cmd.run "dpkg-query --show -f='${Package}|${Version}|${Status}\n'"
      out.first
    end

    # parse the received rpm packages list
    # to get the structure of package names and versions
    # 'package_name' => 'package_version'
    # @returns [Hash<String => String>] packages
    def self.parse_rpm_packages
      packages = {}
      get_rpm_packages.split("\n").each do |package|
        fields = package.split('|')
        name = fields[0]
        version = fields[1]
        if name
          packages.store name, version
        end
      end
      packages
    end

    # parse the received deb packages list
    # to get the structure of package names and versions
    # 'package_name' => 'package_version'
    # @returns [Hash<String => String>] packages
    def self.parse_deb_packages
      packages = {}
      get_deb_packages.split("\n").each do |package|
        fields = package.split('|')
        name = fields[0]
        version = fields[1]
        if fields[2] == 'install ok installed'
          installed = true
        else
          installed = false
        end
        if installed and name
          packages.store name, version
        end
      end
      packages
    end

    # get the installed packages either on Debian or on RedHat system
    # 'package_name' => 'package_version'
    # @returns [Hash<String => String>] packages
    def self.installed_packages
      return @installed_packages if @installed_packages
      if Facts.osfamily == 'RedHat'
        @installed_packages = parse_rpm_packages
      elsif Facts.osfamily == 'Debian'
        @installed_packages = parse_deb_packages
      else
        raise "Unknown osfamily: #{Facts.osfamily}"
      end
    end

    # reset mnemoization
    def self.reset
      @installed_packages = nil
    end

    # check if this package is installed
    # @param package [String] package name
    # @return [true,false]
    def self.is_installed?(package)
      installed_packages.key? package
    end
  end

  module Network
    # check if this url is accessible and gives success HTTP status
    # @param url [String] the url to check
    # @return [true,false]
    def self.url_accessible?(url)
      out = TestCommon::Cmd.run "curl --fail '#{url}' 1>/dev/null 2>/dev/null"
      out.last == 0
    end

    # check is TCP connection can be open to this socket
    # @param host [String] hostname of IP address
    # @param port [String,Numeric] the port number to connect to
    # @return [true,false]
    def self.connection?(host, port)
      begin
        Timeout::timeout(5) do
          sock = TCPSocket.open(host, port)
          sock.close if sock
        end
      rescue
        return false
      end
      true
    end

    # check id TCP connection is closed to this socket
    # inversion on connection?
    # @param host [String] hostname of IP address
    # @param port [String,Numeric] the port number to connect to
    # @return [true,false]
    def self.no_connection?(host, port)
      not connection?(host, port)
    end

    # get the list of names from the named iptables rules
    # most likely created by Puppet
    # @return [Array<String>] the list of rule names
    def self.iptables_rules
      return @iptables_rules if @iptables_rules
      output, code = TestCommon::Cmd.run 'iptables-save'
      return unless code == 0
      comments = []
      output.split("\n").each do |line|
        line =~ %r(--comment\s+"(.*?)")
        next unless $1
        comment = $1.chomp.strip.gsub /^\d+\s+/, ''
        comment.gsub! /\sfrom\s\d+\.\d+\.\d+\.\d+\/\d+/, ''
        comments << comment
      end
      @iptables_rules = comments
    end

    # get the list of ip addresses found on this system's interfaces
    # @return [Array<String>] the list of addresses
    def self.ips
      return @ips if @ips
      ip_out, code = TestCommon::Cmd.run 'ip -4 -o a'
      return unless code == 0
      ips = []
      ip_out.split("\n").each do |line|
        if line =~ /\s+inet\s+([\d\.]*)/
          ips << $1
        end
      end
      @ips = ips
    end

    # get this systems default router
    # @return [String] the default router ip
    def self.default_router
      return @default_router if @default_router
      routes, code = TestCommon::Cmd.run 'ip route'
      return unless code == 0
      routes.split("\n").each do |line|
        if line =~ /^default via ([\d\.]*)/
          return @default_router = $1
        end
      end
      nil
    end

    # try to ping this host and return success
    # @param host [String] the hostname or the ip address to ping
    # @return [true,false]
    def self.ping?(host)
      begin
        out = Timeout::timeout(5) do
          TestCommon::Cmd.run "ping -q -c 1 -W 3 '#{host}'"
        end
      rescue
        return false
      end
      out.last == 0
    end

    # reset mnemoization
    def self.reset
      @iptables_rules = nil
      @ips = nil
      @default_router = nil
    end
  end

  module AMQP
    # use python's kombu library to check is connection
    # to AMQP server is possible with this credentials
    # python's library is used because it's installed everywhere
    # and ruby's library is not
    # @param [String] user
    # @param [String] password
    # @param [String] host
    # @param [String,Numeric] port
    # @param [String] vhost
    # @param [String] protocol
    # @return [true,false]
    def self.connection?(
        user=Settings.rabbit['user'],
        password=Settings.rabbit['password'],
        host='localhost',
        port='5673',
        vhost='/',
        protocol='amqp')
      url = "#{protocol}://#{user}:#{password}@#{host}:#{port}/#{vhost}"
      python = <<-eof
import sys
import kombu

connected = False
try:
    connection = kombu.Connection("#{url}")
    connection.connect()
    connected = connection.connected
    connection.close()
    connection.release()
except Exception as e:
    sys.stdout.write("AMQP error: %s\\n" % e)
if connected:
    sys.exit(0)
else:
    sys.exit(1)
      eof
      system "python -c '#{python}'"
      $?.exitstatus == 0
    end
  end

  module Config
    # parse the ini-style config file
    # 'section/key' => 'value'
    # @param [String] file path to the file
    # @return [Hash<String => String>]
    def self.ini_file(file)
      content = File.read file
      data = {}
      return data unless content
      section = 'default'
      content.split("\n").each do |line|
        line = line.strip
        next if line.start_with? '#'
        next if line == ''
        if line =~ /\[(\S+)\]/
          section = $1.downcase
        elsif line =~ /(\S+)\s*=\s*(.*)/
          data["#{section}/#{$1.downcase}"] = $2
        end
      end
      data
    end

    # check if this ini-style config file hash a value
    # @param [String] file path to the file
    # @param [String] key section/key of the param
    # @param [String] value the value of the param
    # @return [true,false]
    def self.value?(file, key, value)
      key = key.downcase
      key = 'default/' + key unless key.include? '/'
      data = ini_file file
      return !data.key?(key) if value.nil?
      value = value.to_s
      value.capitalize! if %w(true false).include? value
      data[key] == value
    end

    # check if this file contains either a string or a regexp
    # @param file [String] path to the file
    # @param line [String, Regexp] look for this string or regexp
    # @return [true,false]
    def self.has_line?(file, line)
      content = File.read file
      if line.is_a? String
        content.include? line
      elsif line.is_a? Regexp
        not (content =~ line).nil?
      else
        raise 'Line should be a string or a regexp!'
      end
    end
  end

  module Cron
    # check if cronjob exists, ignores comments
    # @param user [String] usernam to check cron for
    # @param cronjob [String, Regexp] pattern look for in cron
    # @return [true,false]
    def self.cronjob_exists?(user, cronjob)
      cmd = "crontab -u #{user} -l"
      out = TestCommon::Cmd.run cmd
      false unless out.last == 0
      out.first[/^\s*[^#]*#{cronjob}/].nil? == false
    end
  end

end
