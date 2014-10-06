require 'rubygems'
require 'facter'
require 'time'
require 'yaml'

module Base
  LOG_FILE = '/var/log/deployment.log'
  ASTUTE_YAML = '/etc/astute.yaml'

  @osfamily = nil
  @dry_run = false

  attr_accessor :dry_run

  # same as fuel_settings but resets mnemoization
  # @return [Hash] setting structure
  def fuel_settings_with_renew
    @fuel_settings = nil
    fuel_settings
  end

  # read asture yaml flle
  # @return [Sting]
  def read_astute_yaml
    begin
      File.read ASTUTE_YAML
    rescue
      nil
    end
  end

  # get astute.yaml settings
  # @return [Hash]
  def fuel_settings
    return @fuel_settings if @fuel_settings
    begin
      @fuel_settings = YAML.load read_astute_yaml
    rescue
      @fuel_settings = {}
    end
    @fuel_settings
  end

  # shortcut. get openstack_version from settings
  # @return [String]
  def openstack_version
    fuel_settings['openstack_version']
  end

  # shortcut. get openstack_version_prev from settings
  # @return [String]
  def openstack_version_prev
    fuel_settings['openstack_version_prev']
  end

  # get osfamily from facter
  # @return [String]
  def osfamily
    return @osfamily if @osfamily
    @osfamily = Facter.value 'osfamily'
  end

  # run the shell command with dry_run support
  # @param cmd [String] Command to run
  def run(cmd)
    ENV['LANG'] = 'C'
    log "Run: #{cmd}"
    if dry_run
      return ['', 0]
    end
    stdout = `#{cmd} 2>&1`
    return_code = $?.exitstatus
    puts stdout
    puts "Return: #{return_code}"
    [stdout, return_code]
  end

  # output a string
  # @param msg [String]
  def log(msg)
     begin
       log_file = LOG_FILE
       open(log_file, 'a') do |file|
         file.puts Time.now.to_s + ': ' + msg
       end
     end
    puts msg
  end

  # remove this library's debug log
  def remove_log
    begin
      File.delete LOG_FILE if File.exists? LOG_FILE
    rescue
      false
    end
  end

  # get current timestamp
  def timestamp
    Time.now.to_i.to_s
  end

end
