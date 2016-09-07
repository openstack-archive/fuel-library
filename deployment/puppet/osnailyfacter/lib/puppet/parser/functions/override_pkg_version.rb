module Puppet::Parser::Functions
  newfunction(:override_pkg_version, :doc => <<-'ENDHEREDOC')  do |args|
    Override package version and add notify all catalog services
    ENDHEREDOC

    resource_type = "Package"
    resource_parameter = "ensure"
    list_of_services = catalog.resources.find_all { |res| res.type == "Service" }

    args[0].each {|pkg_title, pkg_ver|
      catalog_resource = compiler.findresource(resource_type, pkg_title)
      if catalog_resource
        catalog_resource[resource_parameter] = pkg_ver

        if catalog_resource["notify"] and list_of_services
          list_of_services.each { |service|
            catalog_resource["notify"] << service.to_s
          }
        end
      end
    }

  end
end

