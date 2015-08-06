require 'puppet/application'
require 'puppet/util/network_device'


class Puppet::Application::Device < Puppet::Application

  run_mode :agent

  attr_accessor :args, :agent, :host

  def app_defaults
    super.merge({
      :catalog_terminus => :rest,
      :catalog_cache_terminus => :json,
      :node_terminus => :rest,
      :facts_terminus => :network_device,
    })
  end

  def preinit
    # Do an initial trap, so that cancels don't get a stack trace.
    Signal.trap(:INT) do
      $stderr.puts "Cancelling startup"
      exit(0)
    end

    {
      :waitforcert => nil,
      :detailed_exitcodes => false,
      :verbose => false,
      :debug => false,
      :centrallogs => false,
      :setdest => false,
    }.each do |opt,val|
      options[opt] = val
    end

    @args = {}
  end

  option("--centrallogging")
  option("--debug","-d")
  option("--verbose","-v")

  option("--detailed-exitcodes") do |arg|
    options[:detailed_exitcodes] = true
  end

  option("--logdest DEST", "-l DEST") do |arg|
    handle_logdest_arg(arg)
  end

  option("--waitforcert WAITFORCERT", "-w") do |arg|
    options[:waitforcert] = arg.to_i
  end

  option("--port PORT","-p") do |arg|
    @args[:Port] = arg
  end

    def help
      <<-'HELP'

puppet-device(8) -- Manage remote network devices
========

SYNOPSIS
--------
Retrieves all configurations from the puppet master and apply
them to the remote devices configured in /etc/puppet/device.conf.

Currently must be run out periodically, using cron or something similar.

USAGE
-----
  puppet device [-d|--debug] [--detailed-exitcodes] [-V|--version]
                [-h|--help] [-l|--logdest syslog|<file>|console]
                [-v|--verbose] [-w|--waitforcert <seconds>]


DESCRIPTION
-----------
Once the client has a signed certificate for a given remote device, it will
retrieve its configuration and apply it.

USAGE NOTES
-----------
One need a /etc/puppet/device.conf file with the following content:

[remote.device.fqdn]
type <type>
url <url>

where:
 * type: the current device type (the only value at this time is cisco)
 * url: an url allowing to connect to the device

Supported url must conforms to:
 scheme://user:password@hostname/?query

 with:
  * scheme: either ssh or telnet
  * user: username, can be omitted depending on the switch/router configuration
  * password: the connection password
  * query: this is device specific. Cisco devices supports an enable parameter whose
  value would be the enable password.

OPTIONS
-------
Note that any configuration parameter that's valid in the configuration file
is also a valid long argument.  For example, 'server' is a valid configuration
parameter, so you can specify '--server <servername>' as an argument.

* --debug:
  Enable full debugging.

* --detailed-exitcodes:
  Provide transaction information via exit codes. If this is enabled, an exit
  code of '2' means there were changes, an exit code of '4' means there were
  failures during the transaction, and an exit code of '6' means there were both
  changes and failures.

* --help:
  Print this help message

* --logdest:
  Where to send messages.  Choose between syslog, the console, and a log file.
  Defaults to sending messages to syslog, or the console if debugging or
  verbosity is enabled.

* --verbose:
  Turn on verbose reporting.

* --waitforcert:
  This option only matters for daemons that do not yet have certificates
  and it is enabled by default, with a value of 120 (seconds).  This causes
  +puppet agent+ to connect to the server every 2 minutes and ask it to sign a
  certificate request.  This is useful for the initial setup of a puppet
  client.  You can turn off waiting for certificates by specifying a time
  of 0.

EXAMPLE
-------
      $ puppet device --server puppet.domain.com

AUTHOR
------
Brice Figureau


COPYRIGHT
---------
Copyright (c) 2011 Puppet Labs, LLC
Licensed under the Apache 2.0 License
      HELP
    end


  def main
    vardir = Puppet[:vardir]
    confdir = Puppet[:confdir]
    certname = Puppet[:certname]

    # find device list
    require 'puppet/util/network_device/config'
    devices = Puppet::Util::NetworkDevice::Config.devices
    if devices.empty?
      Puppet.err "No device found in #{Puppet[:deviceconfig]}"
      exit(1)
    end
    devices.each_value do |device|
      begin
        Puppet.info "starting applying configuration to #{device.name} at #{device.url}"

        # override local $vardir and $certname
        Puppet.settings.set_value(:confdir, ::File.join(Puppet[:devicedir], device.name), :cli)
        Puppet.settings.set_value(:vardir, ::File.join(Puppet[:devicedir], device.name), :cli)
        Puppet.settings.set_value(:certname, device.name, :cli)

        # this will reload and recompute default settings and create the devices sub vardir, or we hope so :-)
        Puppet.settings.use :main, :agent, :ssl

        # this init the device singleton, so that the facts terminus
        # and the various network_device provider can use it
        Puppet::Util::NetworkDevice.init(device)

        # ask for a ssl cert if needed, but at least
        # setup the ssl system for this device.
        setup_host

        require 'puppet/configurer'
        configurer = Puppet::Configurer.new
        configurer.run(:network_device => true, :pluginsync => Puppet[:pluginsync])
      rescue => detail
        Puppet.log_exception(detail)
      ensure
        Puppet.settings.set_value(:vardir, vardir, :cli)
        Puppet.settings.set_value(:confdir, confdir, :cli)
        Puppet.settings.set_value(:certname, certname, :cli)
        Puppet::SSL::Host.reset
      end
    end
  end

  def setup_host
    @host = Puppet::SSL::Host.new
    waitforcert = options[:waitforcert] || (Puppet[:onetime] ? 0 : Puppet[:waitforcert])
    @host.wait_for_cert(waitforcert)
  end

  def setup
    setup_logs

    args[:Server] = Puppet[:server]
    if options[:centrallogs]
      logdest = args[:Server]

      logdest += ":" + args[:Port] if args.include?(:Port)
      Puppet::Util::Log.newdestination(logdest)
    end

    Puppet.settings.use :main, :agent, :device, :ssl

    # Always ignoreimport for agent. It really shouldn't even try to import,
    # but this is just a temporary band-aid.
    Puppet[:ignoreimport] = true

    # We need to specify a ca location for all of the SSL-related
    # indirected classes to work; in fingerprint mode we just need
    # access to the local files and we don't need a ca.
    Puppet::SSL::Host.ca_location = :remote

    Puppet::Transaction::Report.indirection.terminus_class = :rest

    if Puppet[:catalog_cache_terminus]
      Puppet::Resource::Catalog.indirection.cache_class = Puppet[:catalog_cache_terminus].intern
    end
  end
end
