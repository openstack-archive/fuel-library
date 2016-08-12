require 'puppet'
require 'set'

Puppet::Type.newtype(:update_packages) do
  newparam(:name) do
    desc 'The unique name of this resource'
    isnamevar
  end

  newparam(:packages, :array_matching => :all) do
    desc %q(The list of packages to update.
            It can be either a filter limiting the update only to a set of declared packages,
            or a list of extra packages to generate if they are not present in the catalog.
            If this list is empty the packages mentioned in the package versions data will
            be used instead.
          )
  end

  newparam(:versions) do
    desc %q(The hash of package names and their versions.
            If the package name is found in this hash, it's ensure will be
            changed to the specified value. The key "*" will match all packages and
            the "packages" parameter can be used to limit the set of updated packages.
           )
  end

  newparam(:mode) do
    desc %q(
    What set of packages should be updated?
    * "catalog"   - Only packages defined in the current catalog.
                    Change the ensure values of these packages if their name
                    is mentioned in the versions data.
    * "generate"  - Same as "catalog", but also generate additional package
                    resources for the packages mentioned in the versions
                    structure or in the package list if they are not declared
                    in the catalog.
    * "update"    - Same as "catalog" but also includes the packages installed at
                    the target system which are present in the versions data and not
                    present in the catalog.
    * "installed" - Same as "generate" but work with the packages already installed
                    at the managed system. It will try to update the installed packages
                    if they are mentioned in the versions structure or the package list.

    Default: "catalog"
         )

    newvalues(:catalog)
    newvalues(:generate)
    newvalues(:update)
    newvalues(:installed)
    defaultto(:catalog)
  end

  newparam(:type) do
    desc 'The type of resource to work with. It should be "package" in most cases.'
    defaultto('package')
  end

  newparam(:generate_provider) do
    desc 'Set this provider to the generated package instances.'
  end

  newparam(:instances_provider, :array_matching => :all) do
    desc 'A list of providers filtered from the package instances.'
    defaultto []
  end

  MUNGE_ENSURE = %w(installed latest present)

  # The package type that is being used to work with packages
  # @return [Puppet::Type]
  def package_type
    package_class = Puppet::Type.type(self[:type])
    fail "The puppet class '#{self[:type]}' was not found!" unless package_class
    package_class
  end

  # Find all the package resources in the catalog
  # @return [Array]
  def catalog_package_resources
    return [] unless self.respond_to? :catalog
    return [] unless self.catalog.respond_to? :resources
    self.catalog.resources.select do |resource|
      resource.type.to_s.downcase == self[:type].to_s.downcase
    end
  end

  # Extract the name of the Puppet package resource
  # @param [Puppet::Type] package
  # @return [String]
  def package_name(package)
    name = package.title
    name = package[:name] if package[:name]
    name = name.to_s
    name.freeze if name.respond_to? :freeze
    name
  end

  # A set of packages declared in the catalog
  # @return [Set<String>]
  def catalog_packages_set
    declared_packages = Set.new
    catalog_package_resources.each do |package|
      name = package_name package
      declared_packages.add name
    end
    declared_packages
  end

  # The provided list of packages to update
  # @return [Set<String>]
  def packages_to_update_set
    self[:packages] = [self[:packages]] unless self[:packages].is_a? Array
    if self[:packages] and self[:packages].any?
      Set.new self[:packages]
    elsif self[:versions] and self[:versions].any?
      Set.new self[:versions].reject { |name, _version| name == '*' }.keys
    else
      Set.new
    end
  end

  # Check if the package is included in the package list
  # If the package list is empty it's assumed that there is no
  # filter and all packages should be updated if they are matched
  # by the '*' character in the package versions structure.
  # @return [TrueClass,FalseClass]
  def package_is_included?(name)
    return true unless packages_to_update_set.any?
    packages_to_update_set.include? name
  end

  # Get the package versions from the versions data by the package
  # name or if the '*' key is present.
  # @param [String] name
  # @return [String,Symbol,NilClass]
  def package_version(name)
    # debug "Try to get the version for the package: '#{name}'"
    return unless self[:versions] and self[:versions].any?
    version = self[:versions][name]
    version = self[:versions]['*'] if not version and self[:versions].key? '*'
    # debug "Return: '#{version}'"
    version
  end

  # Retrieve the list of installed packages using the "instances" method.
  # @return [Array<Puppet::Type>]
  def package_instances
    return @package_instances if @package_instances
    @package_instances = package_type.instances
  end

  # A set of installed packages names
  # @return [Set<String>]
  def installed_packages_set
    packages = Set.new
    package_instances.each do |package|
      next unless self[:instances_provider].include? package.provider.class.name.to_s
      packages.add package_name package
    end
    packages
  end

  # Apply the versions data on the packages declared in the
  # catalog if they are in the package list and have a version
  # in the versions data.
  def update_catalog_resources
    debug 'Call: update_catalog_resources'
    catalog_package_resources.each do |package|
      next unless MUNGE_ENSURE.include? package[:ensure].to_s
      name = package_name package
      next unless package_is_included? name
      package_ensure = package_version name
      if package_ensure
        package_message_title = package.title
        package_message_title += " (#{name})" unless package_message_title == name
        debug "Updating an exiting package instance: '#{package_message_title}' ensure to: '#{package_ensure}'"
        package[:ensure] = package_ensure
      end
    end
  end

  # A list of missing packages depending on the mode
  # In the "generate" mode it will be all packages in the package list
  # excluding those which are already present in the catalog.
  # In the "installed" mode it will take all packages in the package list
  # together with the packages already installed at the system excluding
  # the packages already present in the catalog.
  # In the "update" mode only the already installed packages will receive
  # generated instances if they are present in the versions data.
  # In the "catalog" mode no new instances are generated.
  # @return [Set<String>]
  def missing_packages_set
    if self[:mode] == :generate
      packages_to_update_set - catalog_packages_set
    elsif self[:mode] == :installed
      (installed_packages_set + packages_to_update_set) - catalog_packages_set
    elsif self[:mode] == :update
      (packages_to_update_set - catalog_packages_set) & installed_packages_set
    else
      Set.new
    end
  end

  # Create a list of package resources which are not present in the
  # catalog but should be updated because they are present in the package list.
  # If the "installed" mode is enabled, only the packages already installed at
  # the managed system are created.
  # @return [Array<Puppet::Type>]
  def generate_missing_packages
    debug 'Call: generate_missing_packages'
    missing_packages_set.map do |name|
      package_ensure = package_version name
      package_ensure = :present unless package_ensure
      debug "Generating a new package instance: '#{name}' with ensure: '#{package_ensure}'"
      package_hash = {
          :title => name,
          :ensure => package_ensure,
      }
      package_hash[:provider] = self[:generate_provider] if self[:generate_provider]
      package_type.new(package_hash)
    end
  end

  # Show the packages to update list for debugging
  def show_packages_to_update
    debug "Considering to update the packages: #{packages_to_update_set.to_a.sort.join ', '}"
  end

  # Update the Puppet catalog
  # @return [Array<Puppet::Type>]
  def generate
    show_packages_to_update
    update_catalog_resources
    generate_missing_packages
  end
end
