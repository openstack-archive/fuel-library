# Define the different packaging systems.  Each package system is implemented
# in a module, which then gets used to individually extend each package object.
# This allows packages to exist on the same machine using different packaging
# systems.

require 'puppet/parameter/package_options'

module Puppet
  newtype(:package) do
    @doc = "Manage packages.  There is a basic dichotomy in package
      support right now:  Some package types (e.g., yum and apt) can
      retrieve their own package files, while others (e.g., rpm and sun)
      cannot.  For those package formats that cannot retrieve their own files,
      you can use the `source` parameter to point to the correct file.

      Puppet will automatically guess the packaging format that you are
      using based on the platform you are on, but you can override it
      using the `provider` parameter; each provider defines what it
      requires in order to function, and you must meet those requirements
      to use a given provider.

      **Autorequires:** If Puppet is managing the files specified as a
      package's `adminfile`, `responsefile`, or `source`, the package
      resource will autorequire those files."

    feature :installable, "The provider can install packages.",
      :methods => [:install]
    feature :uninstallable, "The provider can uninstall packages.",
      :methods => [:uninstall]
    feature :upgradeable, "The provider can upgrade to the latest version of a
        package.  This feature is used by specifying `latest` as the
        desired value for the package.",
      :methods => [:update, :latest]
    feature :purgeable, "The provider can purge packages.  This generally means
        that all traces of the package are removed, including
        existing configuration files.  This feature is thus destructive
        and should be used with the utmost care.",
      :methods => [:purge]
    feature :versionable, "The provider is capable of interrogating the
        package database for installed version(s), and can select
        which out of a set of available versions of a package to
        install if asked."
    feature :holdable, "The provider is capable of placing packages on hold
        such that they are not automatically upgraded as a result of
        other package dependencies unless explicit action is taken by
        a user or another package. Held is considered a superset of
        installed.",
      :methods => [:hold]
    feature :install_options, "The provider accepts options to be
      passed to the installer command."
    feature :uninstall_options, "The provider accepts options to be
      passed to the uninstaller command."

    ensurable do
      desc <<-EOT
        What state the package should be in. On packaging systems that can
        retrieve new packages on their own, you can choose which package to
        retrieve by specifying a version number or `latest` as the ensure
        value. On packaging systems that manage configuration files separately
        from "normal" system files, you can uninstall config files by
        specifying `purged` as the ensure value. This defaults to `installed`.
      EOT

      attr_accessor :latest

      newvalue(:present, :event => :package_installed) do
        provider.install
      end

      newvalue(:absent, :event => :package_removed) do
        provider.uninstall
      end

      newvalue(:purged, :event => :package_purged, :required_features => :purgeable) do
        provider.purge
      end

      newvalue(:held, :event => :package_held, :required_features => :holdable) do
        provider.hold
      end

      # Alias the 'present' value.
      aliasvalue(:installed, :present)

      newvalue(:latest, :required_features => :upgradeable) do
        # Because yum always exits with a 0 exit code, there's a retrieve
        # in the "install" method.  So, check the current state now,
        # to compare against later.
        current = self.retrieve
        begin
          provider.update
        rescue => detail
          self.fail "Could not update: #{detail}"
        end

        if current == :absent
          :package_installed
        else
          :package_changed
        end
      end

      newvalue(/./, :required_features => :versionable) do
        begin
          provider.install
        rescue => detail
          self.fail "Could not update: #{detail}"
        end

        if self.retrieve == :absent
          :package_installed
        else
          :package_changed
        end
      end

      defaultto :installed

      munge do |value|
        #puts "VALUE #{value} CLASS #{value.class}"
        value = value.to_sym if %w(present installed latest absent purged held).include? value

        if value.is_a? FalseClass
          :absent
        elsif value.is_a? TrueClass
          :installed
        elsif value == :installed
          :present
        else
          value
        end
      end

      # lookup package version in versions file
      # returns nil if version is not found
      # @return <String,NilClass>
      def lookup_version
        package_name = @resource.name.to_s
        versions_file = '/etc/versions.yaml'
        return nil unless File.readable? versions_file
        require 'yaml'
        versions = YAML.load_file versions_file
        return nil unless versions.is_a? Hash
        versions.dup.each do |k, v|
          next if k.is_a? String
          versions.delete k
          versions.store k.to_s, v
        end
        return nil unless versions.key? package_name
        version = versions[package_name].to_s
        Puppet.debug "Got version '#{version}' for package '#{package_name}' from the versions file"
        version
      end

      # modify @should Array if we want to lookup package version
      # returns @should element without Array
      # @return <String,Symbol>
      def should
        value = super
        return value unless [:installed,:present].include? @should.first
        return value unless [:apt, :yum].include? @resource.provider.class.name
        version = lookup_version
        if version
          @should[0] = version
          return version
        end
        value
      end

      # Override the parent method, because we've got all kinds of
      # funky definitions of 'in sync'.
      def insync?(is)
        @lateststamp ||= (Time.now.to_i - 1000)
        # Iterate across all of the should values, and see how they
        # turn out.

        @should.each { |should|
          case should
          when :present
            return true unless [:absent, :purged, :held].include?(is)
          when :latest
            # Short-circuit packages that are not present
            return false if is == :absent or is == :purged

            # Don't run 'latest' more than about every 5 minutes
            if @latest and ((Time.now.to_i - @lateststamp) / 60) < 5
              #self.debug "Skipping latest check"
            else
              begin
                @latest = provider.latest
                @lateststamp = Time.now.to_i
              rescue => detail
                error = Puppet::Error.new("Could not get latest version: #{detail}")
                error.set_backtrace(detail.backtrace)
                raise error
              end
            end

            case
              when is.is_a?(Array) && is.include?(@latest)
                return true
              when is == @latest
                return true
              when is == :present
                # This will only happen on retarded packaging systems
                # that can't query versions.
                return true
              else
                self.debug "#{@resource.name} #{is.inspect} is installed, latest is #{@latest.inspect}"
            end


          when :absent
            return true if is == :absent or is == :purged
          when :purged
            return true if is == :purged
          # this handles version number matches and
          # supports providers that can have multiple versions installed
          when *Array(is)
            return true
          end
        }

        false
      end

      # This retrieves the current state. LAK: I think this method is unused.
      def retrieve
        provider.properties[:ensure]
      end

      # Provide a bit more information when logging upgrades.
      def should_to_s(newvalue = @should)
        if @latest
          @latest.to_s
        else
          super(newvalue)
        end
      end
    end

    newparam(:name) do
      desc "The package name.  This is the name that the packaging
      system uses internally, which is sometimes (especially on Solaris)
      a name that is basically useless to humans.  If you want to
      abstract package installation, then you can use aliases to provide
      a common name to packages:

          # In the 'openssl' class
          $ssl = $operatingsystem ? {
            solaris => SMCossl,
            default => openssl
          }

          # It is not an error to set an alias to the same value as the
          # object name.
          package { $ssl:
            ensure => installed,
            alias  => openssl
          }

          . etc. .

          $ssh = $operatingsystem ? {
            solaris => SMCossh,
            default => openssh
          }

          # Use the alias to specify a dependency, rather than
          # having another selector to figure it out again.
          package { $ssh:
            ensure  => installed,
            alias   => openssh,
            require => Package[openssl]
          }

      "
      isnamevar

      validate do |value|
        if !value.is_a?(String)
          raise ArgumentError, "Name must be a String not #{value.class}"
        end
      end
    end

    newparam(:source) do
      desc "Where to find the actual package.  This must be a local file
        (or on a network file system) or a URL that your specific
        packaging type understands; Puppet will not retrieve files for you,
        although you can manage packages as `file` resources."

      validate do |value|
        provider.validate_source(value)
      end
    end

    newparam(:instance) do
      desc "A read-only parameter set by the package."
    end

    newparam(:status) do
      desc "A read-only parameter set by the package."
    end

    newparam(:adminfile) do
      desc "A file containing package defaults for installing packages.
        This is currently only used on Solaris.  The value will be
        validated according to system rules, which in the case of
        Solaris means that it should either be a fully qualified path
        or it should be in `/var/sadm/install/admin`."
    end

    newparam(:responsefile) do
      desc "A file containing any necessary answers to questions asked by
        the package.  This is currently used on Solaris and Debian.  The
        value will be validated according to system rules, but it should
        generally be a fully qualified path."
    end

    newparam(:configfiles) do
      desc "Whether configfiles should be kept or replaced.  Most packages
        types do not support this parameter. Defaults to `keep`."

      defaultto :keep

      newvalues(:keep, :replace)
    end

    newparam(:category) do
      desc "A read-only parameter set by the package."
    end
    newparam(:platform) do
      desc "A read-only parameter set by the package."
    end
    newparam(:root) do
      desc "A read-only parameter set by the package."
    end
    newparam(:vendor) do
      desc "A read-only parameter set by the package."
    end
    newparam(:description) do
      desc "A read-only parameter set by the package."
    end

    newparam(:allowcdrom) do
      desc "Tells apt to allow cdrom sources in the sources.list file.
        Normally apt will bail if you try this."

      newvalues(:true, :false)
    end

    newparam(:flavor) do
      desc "OpenBSD supports 'flavors', which are further specifications for
        which type of package you want."
    end

    newparam(:install_options, :parent => Puppet::Parameter::PackageOptions, :required_features => :install_options) do
      desc <<-EOT
        An array of additional options to pass when installing a package. These
        options are package-specific, and should be documented by the software
        vendor.  One commonly implemented option is `INSTALLDIR`:

            package { 'mysql':
              ensure          => installed,
              source          => 'N:/packages/mysql-5.5.16-winx64.msi',
              install_options => [ '/S', { 'INSTALLDIR' => 'C:\\mysql-5.5' } ],
            }

        Each option in the array can either be a string or a hash, where each
        key and value pair are interpreted in a provider specific way.  Each
        option will automatically be quoted when passed to the install command.

        On Windows, this is the **only** place in Puppet where backslash
        separators should be used.  Note that backslashes in double-quoted
        strings _must_ be double-escaped and backslashes in single-quoted
        strings _may_ be double-escaped.
      EOT
    end

    newparam(:uninstall_options, :parent => Puppet::Parameter::PackageOptions, :required_features => :uninstall_options) do
      desc <<-EOT
        An array of additional options to pass when uninstalling a package. These
        options are package-specific, and should be documented by the software
        vendor.  For example:

            package { 'VMware Tools':
              ensure            => absent,
              uninstall_options => [ { 'REMOVE' => 'Sync,VSS' } ],
            }

        Each option in the array can either be a string or a hash, where each
        key and value pair are interpreted in a provider specific way.  Each
        option will automatically be quoted when passed to the uninstall
        command.

        On Windows, this is the **only** place in Puppet where backslash
        separators should be used.  Note that backslashes in double-quoted
        strings _must_ be double-escaped and backslashes in single-quoted
        strings _may_ be double-escaped.
      EOT
    end

    autorequire(:file) do
      autos = []
      [:responsefile, :adminfile].each { |param|
        if val = self[param]
          autos << val
        end
      }

      if source = self[:source] and absolute_path?(source)
        autos << source
      end
      autos
    end

    # This only exists for testing.
    def clear
      if obj = @parameters[:ensure]
        obj.latest = nil
      end
    end

    # The 'query' method returns a hash of info if the package
    # exists and returns nil if it does not.
    def exists?
      @provider.get(:ensure) != :absent
    end
  end
end
