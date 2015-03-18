require 'hiera'
require 'test/unit'
require 'open-uri'
require 'timeout'
require 'facter'
require 'socket'

module TestCommon

  module Settings
    def self.hiera
      return @hiera if @hiera
      @hiera = Hiera.new(:config => '/etc/puppet/hiera.yaml')
    end

    def self.lookup(key)
      key = key.to_s
      key = 'rabbit_hash' if key == 'rabbit'
      @keys = {} unless @keys
      return @keys[key] if @keys[key]
      @keys[key] = hiera.lookup key, nil, {}
    end

    def self.method_missing(key)
      lookup key
    end

    def self.[](key)
      lookup key
    end
  end

  module HAProxy
    def self.stats_url
      ip = Settings.management_vip
      ip = Settings.controller_node_address unless ip
      raise 'Could not get internal address!' unless ip
      port = 10000
      "http://#{ip}:#{port}/;csv"
    end

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

    def self.backend_present?(backend)
      backends.keys.include? backend
    end

    def self.backend_up?(backend)
      backends[backend] == 'UP'
    end
  end

  module Process

    def self.run_successful?(cmd)
      `#{cmd}`
      $?.exitstatus == 0
    end

    def self.command_present?(command)
      run_successful? "which '#{command}' 1>/dev/null 2>/dev/null"
    end

    def self.list
      return @process_list if @process_list
      @process_list = []
      ps = `ps haxo cmd`
      ps.split("\n").each do |cmd|
        @process_list << cmd
      end
      @process_list
    end

    def self.running?(process)
      not list.find { |cmd| cmd.include? process }.nil?
    end

    def self.tree
      return @process_tree if @process_tree
      @process_tree = {}
      ps = `ps haxo pid,ppid,cmd`
      ps.split("\n").each do |p|
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

  end

  module MySQL
    @pass = nil
    @user = nil
    @host = nil
    @port = nil
    @db = nil
    @options = '--raw --skip-column-names --batch'

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

    def self.query(query)
      query = query.gsub %q('), %q(")
      command = %Q(mysql #{options} --execute='#{query}')
      command += %Q( --host='#{host}') if host
      command += %Q( --user='#{user}') if user
      command += %Q( --password='#{pass}') if pass
      command += %Q( --port='#{port}') if port
      command += %Q( --database='#{db}') if db
      out = `#{command}`
      code = $?.exitstatus
      return out, code
    end

    def self.connection?
      result = query 'show databases'
      result.last == 0
    end

    def self.databases
      return @databases if @databases
      out, code = query 'show databases'
      return unless code == 0
      @databases = []
      out.split('\n').each do |db|
        @databases << db
      end
      @databases
    end

    def self.database_exists?(database)
      databases.include?(database)
    end

  end

  module Pacemaker
    def self.online?
      Timeout::timeout(5) { `cibadmin -Q` } rescue return false
      $?.exitstatus == 0
    end

    def self.primitives
      list = Timeout::timeout(5) { `crm_resource -l` } rescue return
      primitives = []
      list.split("\n").each do |line|
        primitives << line.split(':').first
      end
      primitives
    end

    def self.clean_primitive_name(primitive)
      primitive = primitive.gsub /^clone_/, ''
      primitive = primitive.gsub /^master_/, ''
      primitive
    end

    def self.primitive_present?(primitive)
      primitive = clean_primitive_name primitive
      primitives.include? primitive
    end

    def self.primitive_started?(primitive)
      primitive = clean_primitive_name primitive
      out = Timeout::timeout(5) { `crm_resource -r #{primitive} -W 2>&1` } rescue return
      return true if out.include? 'is running on'
      return false if out.include? 'is NOT running'
      nil
    end

  end

  module Facts
    def self.osfamily
      return @osfamily if @osfamily
      @osfamily = Facter.value 'osfamily'
    end
  end

  module Package
    def self.get_rpm_packages
      `rpm -qa --queryformat '%{NAME}|%{VERSION}-%{RELEASE}\n'`
    end

    def self.get_deb_packages
      `dpkg-query --show -f='${Package}|${Version}|${Status}\n'`
    end

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

    def self.is_installed?(package)
      installed_packages.key? package
    end
  end

  module Network
    def self.url_accessible?(url)
      `curl --fail '#{url}' 1>/dev/null 2>/dev/null`
      $?.exitstatus == 0
    end

    def self.connection?(host, port)
      begin
        Timeout::timeout(5) do
          sock = TCPSocket.open(host, port)
          sock.close
        end
      rescue
        return false
      end
      true
    end

    def self.no_connection?(host, port)
      not connection?(host, port)
    end

    def self.iptables_rules
      return @iptables_rules if @iptables_rules
      output = `iptables-save`
      code = $?.exitstatus
      return unless code == 0
      comments = []
      output.split("\n").each do |line|
        line =~ %r(--comment\s+"(.*?)")
        next unless $1
        comment = $1.chomp.strip.gsub /^\d+\s+/, ''
        comments << comment
      end
      @iptables_rules = comments
    end

    def self.ips
      return @ips if @ips
      ip_out = `ip addr`
      return unless $?.exitstatus == 0
      ips = []
      ip_out.split("\n").each do |line|
        if line =~ /\s+inet\s+([\d\.]*)/
          ips << $1
        end
      end
      @ips = ips
    end

    def self.default_router
      return @default_router if @default_router
      routes = `ip route`
      return unless $?.exitstatus == 0
      routes.split("\n").each do |line|
        if line =~ /^default via ([\d\.]*)/
          return @default_router = $1
        end
      end
      nil
    end

    def self.ping?(host)
      `ping -q -c 1 -W 3 '#{host}'`
      $?.exitstatus == 0
    end
  end

  module AMQP
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

    def self.value?(file, key, value)
      key = key.downcase
      key = 'default/' + key unless key.include? '/'
      value = value.to_s
      data = ini_file file
      data[key] == value
    end

    def self.has_line?(file, line)
      content = File.read file
      if line.is_a? String
        content.include? line
      elsif line.is_a? Regexp
        content =~ line
      else
        raise 'Line should be a string or a regexp!'
      end
    end
  end

end
