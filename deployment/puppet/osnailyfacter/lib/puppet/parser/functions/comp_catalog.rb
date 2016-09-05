module Puppet::Parser::Functions
  newfunction(:comp_catalog, :type => :rvalue, :doc => <<-'ENDHEREDOC')  do |args|
    Whether package names from hash are in the puppet catalog
    ENDHEREDOC

    resource_type = "package"
    args[0].each {|elem|
      catalog_resource = compiler.findresource(resource_type, elem)
      if catalog_resource
       return 1
      end
    }
    return nil
  end
end
