Puppet::Face.define(:module, '1.0.0') do
  action(:build) do
    summary "Build a module release package."
    description <<-EOT
      Prepares a local module for release on the Puppet Forge by building a
      ready-to-upload archive file.

      This action uses the Modulefile in the module directory to set metadata
      used by the Forge. See <http://links.puppetlabs.com/modulefile> for more
      about writing modulefiles.

      After being built, the release archive file can be found in the module's
      `pkg` directory.
    EOT

    returns "Pathname object representing the path to the release archive."

    examples <<-EOT
      Build a module release:

      $ puppet module build puppetlabs-apache
      notice: Building /Users/kelseyhightower/puppetlabs-apache for release
      Module built: /Users/kelseyhightower/puppetlabs-apache/pkg/puppetlabs-apache-0.0.1.tar.gz

      Build the module in the current working directory:

      $ cd /Users/kelseyhightower/puppetlabs-apache
      $ puppet module build
      notice: Building /Users/kelseyhightower/puppetlabs-apache for release
      Module built: /Users/kelseyhightower/puppetlabs-apache/pkg/puppetlabs-apache-0.0.1.tar.gz
    EOT

    arguments "[<path>]"

    when_invoked do |*args|
      options = args.pop
      if options.nil? or args.length > 1 then
        raise ArgumentError, "puppet module build only accepts 0 or 1 arguments"
      end

      module_path = args.first
      if module_path.nil?
        pwd = Dir.pwd
        module_path = Puppet::ModuleTool.find_module_root(pwd)
        if module_path.nil?
          raise "Unable to find module root at #{pwd} or parent directories"
        end
      else
        unless Puppet::ModuleTool.is_module_root?(module_path)
          raise "Unable to find module root at #{module_path}"
        end
      end

      Puppet::ModuleTool.set_option_defaults options
      Puppet::ModuleTool::Applications::Builder.run(module_path, options)
    end

    when_rendering :console do |return_value|
      # Get the string representation of the Pathname object.
      "Module built: " + return_value.expand_path.to_s
    end
  end
end
