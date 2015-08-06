Puppet::Util::Log.newdesttype :syslog do
  def self.suitable?(obj)
    Puppet.features.syslog?
  end

  def close
    Syslog.close
  end

  def initialize
    Syslog.close if Syslog.opened?
    name = "puppet-#{Puppet.run_mode.name}"

    options = Syslog::LOG_PID | Syslog::LOG_NDELAY

    # XXX This should really be configurable.
    str = Puppet[:syslogfacility]
    begin
      facility = Syslog.const_get("LOG_#{str.upcase}")
    rescue NameError
      raise Puppet::Error, "Invalid syslog facility #{str}"
    end

    @syslog = Syslog.open(name, options, facility)
  end

  def handle(msg)
    # XXX Syslog currently has a bug that makes it so you
    # cannot log a message with a '%' in it.  So, we get rid
    # of them.
    if msg.source == "Puppet"
      msg.to_s.split("\n").each do |line|
        @syslog.send(msg.level, line.gsub("%", '%%'))
      end
    else
      msg.to_s.split("\n").each do |line|
        @syslog.send(msg.level, "(%s) %s" % [msg.source.to_s.gsub("%", ""),
            line.gsub("%", '%%')
          ]
        )
      end
    end
  end
end

Puppet::Util::Log.newdesttype :file do
  require 'fileutils'

  def self.match?(obj)
    Puppet::Util.absolute_path?(obj)
  end

  def close
    if defined?(@file)
      @file.close
      @file = nil
    end
  end

  def flush
    @file.flush if defined?(@file)
  end

  attr_accessor :autoflush

  def initialize(path)
    @name = path
    # first make sure the directory exists
    # We can't just use 'Config.use' here, because they've
    # specified a "special" destination.
    unless Puppet::FileSystem::File.exist?(File.dirname(path))
      FileUtils.mkdir_p(File.dirname(path), :mode => 0755)
      Puppet.info "Creating log directory #{File.dirname(path)}"
    end

    # create the log file, if it doesn't already exist
    file = File.open(path, File::WRONLY|File::CREAT|File::APPEND)

    # Give ownership to the user and group puppet will run as
    begin
      FileUtils.chown(Puppet[:user], Puppet[:group], path) unless Puppet::Util::Platform.windows?
    rescue ArgumentError, Errno::EPERM
      Puppet.err "Unable to set ownership of log file"
    end

    @file = file

    @autoflush = Puppet[:autoflush]
  end

  def handle(msg)
    @file.puts("#{msg.time} #{msg.source} (#{msg.level}): #{msg}")

    @file.flush if @autoflush
  end
end

Puppet::Util::Log.newdesttype :logstash_event do
  require 'time'

  def format(msg)
    # logstash_event format is documented at
    # https://logstash.jira.com/browse/LOGSTASH-675

    data = {}
    data = msg.to_hash
    data['version'] = 1
    data['@timestamp'] = data['time']
    data.delete('time')

    data
  end

  def handle(msg)
    message = format(msg)
    $stdout.puts message.to_pson
  end
end

Puppet::Util::Log.newdesttype :console do
  require 'puppet/util/colors'
  include Puppet::Util::Colors

  def initialize
    # Flush output immediately.
    $stderr.sync = true
    $stdout.sync = true
  end

  def handle(msg)
    levels = {
      :emerg   => { :name => 'Emergency', :color => :hred,  :stream => $stderr },
      :alert   => { :name => 'Alert',     :color => :hred,  :stream => $stderr },
      :crit    => { :name => 'Critical',  :color => :hred,  :stream => $stderr },
      :err     => { :name => 'Error',     :color => :hred,  :stream => $stderr },
      :warning => { :name => 'Warning',   :color => :hred,  :stream => $stderr },

      :notice  => { :name => 'Notice',    :color => :reset, :stream => $stdout },
      :info    => { :name => 'Info',      :color => :green, :stream => $stdout },
      :debug   => { :name => 'Debug',     :color => :cyan,  :stream => $stdout },
    }

    str = msg.respond_to?(:multiline) ? msg.multiline : msg.to_s
    str = msg.source == "Puppet" ? str : "#{msg.source}: #{str}"

    level = levels[msg.level]
    level[:stream].puts colorize(level[:color], "#{level[:name]}: #{str}")
  end
end

# Log to a transaction report.
Puppet::Util::Log.newdesttype :report do
  attr_reader :report

  match "Puppet::Transaction::Report"

  def initialize(report)
    @report = report
  end

  def handle(msg)
    @report << msg
  end
end

# Log to an array, just for testing.
module Puppet::Test
  class LogCollector
    def initialize(logs)
      @logs = logs
    end

    def <<(value)
      @logs << value
    end
  end
end

Puppet::Util::Log.newdesttype :array do
  match "Puppet::Test::LogCollector"

  def initialize(messages)
    @messages = messages
  end

  def handle(msg)
    @messages << msg
  end
end

Puppet::Util::Log.newdesttype :eventlog do
  def self.suitable?(obj)
    Puppet.features.eventlog?
  end

  def initialize
    @eventlog = Win32::EventLog.open("Application")
  end

  def to_native(level)
    case level
    when :debug,:info,:notice
      [Win32::EventLog::INFO, 0x01]
    when :warning
      [Win32::EventLog::WARN, 0x02]
    when :err,:alert,:emerg,:crit
      [Win32::EventLog::ERROR, 0x03]
    end
  end

  def handle(msg)
    native_type, native_id = to_native(msg.level)

    @eventlog.report_event(
      :source      => "Puppet",
      :event_type  => native_type,
      :event_id    => native_id,
      :data        => (msg.source and msg.source != 'Puppet' ? "#{msg.source}: " : '') + msg.to_s
    )
  end

  def close
    if @eventlog
      @eventlog.close
      @eventlog = nil
    end
  end
end
