require 'puppet/util/inifile'

module Puppet
  # A property for one entry in a .ini-style file
  class IniProperty < Puppet::Property
    def insync?(is)
      # A should property of :absent is the same as nil
      if is.nil? && should == :absent
        return true
      end
      super(is)
    end

    def sync
      if safe_insync?(retrieve)
        result = nil
      else
        result = set(self.should)
        if should == :absent
          resource.section[inikey] = nil
        else
          resource.section[inikey] = should
        end
      end
      result
    end

    def retrieve
      resource.section[inikey]
    end

    def inikey
      name.to_s
    end

    # Set the key associated with this property to KEY, instead
    # of using the property's NAME
    def self.inikey(key)
      # Override the inikey instance method
      # Is there a way to do this without resorting to strings ?
      # Using a block fails because the block can't access
      # the variable 'key' in the outer scope
      self.class_eval("def inikey ; \"#{key.to_s}\" ; end")
    end

  end

  # Doc string for properties that can be made 'absent'
  ABSENT_DOC="Set this to `absent` to remove it from the file completely."

  newtype(:yumrepo) do
    @doc = "The client-side description of a yum repository. Repository
      configurations are found by parsing `/etc/yum.conf` and
      the files indicated by the `reposdir` option in that file
      (see `yum.conf(5)` for details).

      Most parameters are identical to the ones documented
      in the `yum.conf(5)` man page.

      Continuation lines that yum supports (for the `baseurl`, for example)
      are not supported. This type does not attempt to read or verify the
      exinstence of files listed in the `include` attribute."

    class << self
      attr_accessor :filetype
      # The writer is only used for testing, there should be no need
      # to change yumconf or inifile in any other context
      attr_accessor :yumconf
      attr_writer :inifile
    end

    self.filetype = Puppet::Util::FileType.filetype(:flat)

    @inifile = nil

    @yumconf = "/etc/yum.conf"

    # Where to put files for brand new sections
    @defaultrepodir = nil

    def self.instances
      l = []
      check = validproperties
      clear
      inifile.each_section do |s|
        next if s.name == "main"
        obj = new(:name => s.name, :audit => check)
        current_values = obj.retrieve
        obj.eachproperty do |property|
          if current_values[property].nil?
            obj.delete(property.name)
          else
            property.should = current_values[property]
          end
        end
        obj.delete(:audit)
        l << obj
      end
      l
    end

    # Return the Puppet::Util::IniConfig::File for the whole yum config
    def self.inifile
      if @inifile.nil?
        @inifile = read
        main = @inifile['main']
        raise Puppet::Error, "File #{yumconf} does not contain a main section" if main.nil?
        reposdir = main['reposdir']
        reposdir ||= "/etc/yum.repos.d, /etc/yum/repos.d"
        reposdir.gsub!(/[\n,]/, " ")
        reposdir.split.each do |dir|
          Dir::glob("#{dir}/*.repo").each do |file|
            @inifile.read(file) if ::File.file?(file)
          end
        end
        reposdir.split.each do |dir|
          if ::File.directory?(dir) && ::File.writable?(dir)
            @defaultrepodir = dir
            break
          end
        end
      end
      @inifile
    end

    # Parse the yum config files. Only exposed for the tests
    # Non-test code should use self.inifile to get at the
    # underlying file
    def self.read
      result = Puppet::Util::IniConfig::File.new
      result.read(yumconf)
      main = result['main']
      raise Puppet::Error, "File #{yumconf} does not contain a main section" if main.nil?
      reposdir = main['reposdir']
      reposdir ||= "/etc/yum.repos.d, /etc/yum/repos.d"
      reposdir.gsub!(/[\n,]/, " ")
      reposdir.split.each do |dir|
        Dir::glob("#{dir}/*.repo").each do |file|
          result.read(file) if ::File.file?(file)
        end
      end
      if @defaultrepodir.nil?
        reposdir.split.each do |dir|
          if ::File.directory?(dir) && ::File.writable?(dir)
            @defaultrepodir = dir
            break
          end
        end
      end
      result
    end

    # Return the Puppet::Util::IniConfig::Section with name NAME
    # from the yum config
    def self.section(name)
      result = inifile[name]
      if result.nil?
        # Brand new section
        path = yumconf
        path = ::File.join(@defaultrepodir, "#{name}.repo") unless @defaultrepodir.nil?
        Puppet::info "create new repo #{name} in file #{path}"
        result = inifile.add_section(name, path)
      end
      result
    end

    # Store all modifications back to disk
    def self.store
      inifile.store
      unless Puppet[:noop]
        target_mode = 0644 # FIXME: should be configurable
        inifile.each_file do |file|
          current_mode = Puppet::FileSystem::File.new(file).stat.mode & 0777
          unless current_mode == target_mode
            Puppet::info "changing mode of #{file} from %03o to %03o" % [current_mode, target_mode]
            ::File.chmod(target_mode, file)
          end
        end
      end
    end

    # This is only used during testing.
    def self.clear
      @inifile = nil
      @yumconf = "/etc/yum.conf"
      @defaultrepodir = nil
    end

    # Return the Puppet::Util::IniConfig::Section for this yumrepo resource
    def section
      self.class.section(self[:name])
    end

    # Store modifications to this yumrepo resource back to disk
    def flush
      self.class.store
    end

    newparam(:name) do
      desc "The name of the repository.  This corresponds to the
        `repositoryid` parameter in `yum.conf(5)`."
      isnamevar
    end

    newproperty(:descr, :parent => Puppet::IniProperty) do
      desc "A human-readable description of the repository.
        This corresponds to the name parameter in `yum.conf(5)`.
        #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(/.*/) { }
      inikey "name"
    end

    newproperty(:mirrorlist, :parent => Puppet::IniProperty) do
      desc "The URL that holds the list of mirrors for this repository.
        #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      # Should really check that it's a valid URL
      newvalue(/.*/) { }
    end

    newproperty(:baseurl, :parent => Puppet::IniProperty) do
      desc "The URL for this repository. #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      # Should really check that it's a valid URL
      newvalue(/.*/) { }
    end

    newproperty(:enabled, :parent => Puppet::IniProperty) do
      desc "Whether this repository is enabled, as represented by a
        `0` or `1`. #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(/^(0|1)$/) { }
    end

    newproperty(:gpgcheck, :parent => Puppet::IniProperty) do
      desc "Whether to check the GPG signature on packages installed
        from this repository, as represented by a `0` or `1`.
        #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(/^(0|1)$/) { }
    end

    newproperty(:gpgkey, :parent => Puppet::IniProperty) do
      desc "The URL for the GPG key with which packages from this
        repository are signed. #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      # Should really check that it's a valid URL
      newvalue(/.*/) { }
    end

    newproperty(:include, :parent => Puppet::IniProperty) do
      desc "The URL of a remote file containing additional yum configuration
        settings. Puppet does not check for this file's existence or validity.
        #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      # Should really check that it's a valid URL
      newvalue(/.*/) { }
    end

    newproperty(:exclude, :parent => Puppet::IniProperty) do
      desc "List of shell globs. Matching packages will never be
        considered in updates or installs for this repo.
        #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(/.*/) { }
    end

    newproperty(:includepkgs, :parent => Puppet::IniProperty) do
      desc "List of shell globs. If this is set, only packages
        matching one of the globs will be considered for
        update or install from this repo. #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(/.*/) { }
    end

    newproperty(:enablegroups, :parent => Puppet::IniProperty) do
      desc "Whether yum will allow the use of package groups for this
        repository, as represented by a `0` or `1`. #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(/^(0|1)$/) { }
    end

    newproperty(:failovermethod, :parent => Puppet::IniProperty) do
      desc "The failover methode for this repository; should be either
        `roundrobin` or `priority`. #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(%r{roundrobin|priority}) { }
    end

    newproperty(:keepalive, :parent => Puppet::IniProperty) do
      desc "Whether HTTP/1.1 keepalive should be used with this repository, as
        represented by a `0` or `1`. #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(/^(0|1)$/) { }
    end

     newproperty(:http_caching, :parent => Puppet::IniProperty) do
       desc "What to cache from this repository. #{ABSENT_DOC}"
       newvalue(:absent) { self.should = :absent }
       newvalue(%r(packages|all|none)) { }
     end

    newproperty(:timeout, :parent => Puppet::IniProperty) do
      desc "Number of seconds to wait for a connection before timing
        out. #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(%r{[0-9]+}) { }
    end

    newproperty(:metadata_expire, :parent => Puppet::IniProperty) do
      desc "Number of seconds after which the metadata will expire.
        #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(%r{[0-9]+}) { }
    end

    newproperty(:protect, :parent => Puppet::IniProperty) do
      desc "Enable or disable protection for this repository. Requires
        that the `protectbase` plugin is installed and enabled.
        #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(/^(0|1)$/) { }
    end

    newproperty(:priority, :parent => Puppet::IniProperty) do
      desc "Priority of this repository from 1-99. Requires that
        the `priorities` plugin is installed and enabled.
        #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(%r{[1-9][0-9]?}) { }
    end

    newproperty(:cost, :parent => Puppet::IniProperty) do
      desc "Cost of this repository. #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(%r{\d+}) { }
    end

    newproperty(:proxy, :parent => Puppet::IniProperty) do
      desc "URL to the proxy server for this repository. #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      # Should really check that it's a valid URL
      newvalue(/.*/) { }
    end

    newproperty(:proxy_username, :parent => Puppet::IniProperty) do
      desc "Username for this proxy. #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(/.*/) { }
    end

    newproperty(:proxy_password, :parent => Puppet::IniProperty) do
      desc "Password for this proxy. #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(/.*/) { }
    end

    newproperty(:s3_enabled, :parent => Puppet::IniProperty) do
      desc "Access the repo via S3. #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(/^(0|1)$/) { }
    end

    newproperty(:sslcacert, :parent => Puppet::IniProperty) do
      desc "Path to the directory containing the databases of the
        certificate authorities yum should use to verify SSL certificates.
        #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(/.*/) { }
    end

    newproperty(:sslverify, :parent => Puppet::IniProperty) do
      desc "Should yum verify SSL certificates/hosts at all.
        Possible values are 'True' or 'False'.
        #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(%r(True|False)) { }
    end

    newproperty(:sslclientcert, :parent => Puppet::IniProperty) do
      desc "Path  to the SSL client certificate yum should use to connect
        to repos/remote sites. #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(/.*/) { }
    end

    newproperty(:sslclientkey, :parent => Puppet::IniProperty) do
      desc "Path to the SSL client key yum should use to connect
        to repos/remote sites. #{ABSENT_DOC}"
      newvalue(:absent) { self.should = :absent }
      newvalue(/.*/) { }
    end
  end
end
