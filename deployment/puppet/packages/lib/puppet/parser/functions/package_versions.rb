module Puppet::Parser::Functions
  newfunction(:package_versions, :doc => <<-EOS
Override package versions in the catalog.

Example:

$versions = {
  'package_name' => 'package_version',
}

package_versions($versions)

# It will override the "ensure" value of the package resource
# in the catalog if the package with this name is found.
  EOS
  ) do |args|
    debug 'Call: package_versions'
    versions = args[0] || {}

    raise ArgumentError, "package_versions() Versions should be a hash! Got: #{versions.inspect}" unless versions.is_a? Hash
    raise ArgumentError, 'Catalog was not found in the scope!' unless self.respond_to? :catalog and self.catalog.respond_to? :resources

    unless versions.any?
      info 'package_versions() Versions hash is empty, exiting without doing anything.'
      break({})
    end

    changed_resources = {}

    self.catalog.resources.each do |resource|
      next unless %w(Package Puppet::Type::Package).include? resource.type
      name = resource.title
      name = resource[:name] if resource.keys.include? :name
      next unless versions.key? name
      value = versions[name].to_s
      identifier = "Package[#{resource.title}]"
      identifier += " (#{name})" if resource.title != name
      info "package_versions() Changing #{identifier} ensure from: #{resource[:ensure].inspect} to: #{value.inspect}"
      resource[:ensure] = value
      changed_resources[name] = value
    end

    changed_resources
  end
end
