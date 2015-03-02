require 'hiera'
require 'test/unit'
require 'open-uri'
require 'timeout'
require 'facter'

module TestCommon

  module Settings
    def self.hiera
      return @hiera if @hiera
      @hiera = Hiera.new(:config => '/etc/puppet/hiera.yaml')
    end

    def self.management_vip
      return @management_vip if @management_vip
      @management_vip = hiera.lookup 'management_vip', nil, {}
    end

    def self.controller_node_address
      return @controller_node_address if @controller_node_address
      @controller_node_address = hiera.lookup 'controller_node_address', nil, {}
    end

    def self.mysql
      return @mysql if @mysql
      @mysql = hiera.lookup 'mysql_hash', {}, {}
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

  module PS

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
      list.find { |cmd| cmd.include? process }
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
    @options = '--raw --skip-column-names --batch'

    def self.no_auth
      @pass = nil
      @user = nil
      @host = nil
      @port = nil
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

end

if __FILE__ == $1
  require 'pry'
  TestCommon.pry
end
