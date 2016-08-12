# Package update

## Package_versions functions

This function takes the hash with package names and their versions as an argument.
Then it finds all the package resources in the catalog and updates their ensure value
to the value specified in the package versions hash.
If there is a value for the '*' package in the versions hash, all the packages which
have no record of their own will be updated.

* The simplest possible way and the least intrusive too.
* All changes to the catalog is done during the catalog
  compilation making it the most RSpec friendly solution.
* Requires including this function at the end of every task
  and LCM manifest, making this function parse order dependant.
* Will not affect manifests without this function explicitly included.
* Will not affect packages not in the catalog, so the dependencies
  may not be updated.
* Will work fine with both puppet master and puppet apply, works on the
  master side and requires the data to be present there.
* Can accept input data from any source, not only from the Hiera.
* Has no ability to create new package instances and cannot get any
  information from the managed system.

## Overriding the package type or provider

Putting the custom package type to the Puppet modules will override the
built in one with the custom behaviour. The new type does the Hiera lookup
to extract the package versions data and then updates the ensure value for
the packages found in the packages hash. If there is the “*” record in the
package version data all packages will be affected.

* Does not require any changes to the task or manifests,
  affects everything run on the master and managed nodes.

* Does not provide any way to limit what if affected but
  removing the package versions data or the type itself.

* Will not affect packages not in the catalog and may
  not update the dependencies.

* Types are working on the client side and will require the
  package versions data to be present on the managed nodes.

* Will take data only from the Hiera lookup. Taking data from any
  other source is not possible without extensive changes in the manifests.

* Theoretically can create new resources and access the system state
  but without ability to limit the scope of its effect it can be dangerous.


## Package update resource

The special puppet "meta-resource" borrowing its ideas from the "resources"
built-in Puppet type. It uses the “generate” method to update the resources
in the catalog with the version data taken from the Hiera lookup or from any
other source and, optionally, to create the new package instances to update
dependencies and other packages.

* Requires including this resource to every task or manifests but including it
  is not parse order dependent and can be included anywhere.

* Will affect only the task and manifests which include it.

* Can affect both packages in the catalog and generate new package instances.

* Can retrieve the list of already installed packages and update only them if
  the new version is provided in the versions data.

* Work on the client side but can get data from the catalog form on the master
  side, so it will for fine in both master and master-less environments and
  requires versions data to be present on the master side.

* Can get the versions data from any sources.

* Has the package filter list allowing to limit the packages affected as well
  as add new packages to the update list.

* Uses the built-in package type to update the packages and will use the custom
  apt providers transparently is they are present.

* In the **Catalog** mode will work the same way as the update packages
  function affecting only the packages in the catalog but not their dependencies
  but without parse order dependency.

* In the **Generate** mode it will not only update the existing packages but also
  will create new package instances for the other packages mentioned in the package
  versions data and the package list, working similar to the ensure_packages function
  but without being parse order dependent and creating
  annoying duplicate declaration errors.

* In the **Update** mode it will not only updates the packages in the current catalog
  but also will update any packages already installed at the target system with a new
  version present in the versions data by receiving the list of installed packages
  creating new package instances for them.

* In the **Installed** mode it will not only update the packages in the current catalog
  but will also create instances for every package installed at the target system
  overriding their versions if the package is present in the versions data as well as
  creating package instances for the packages mentioned in the versions data but found
  neither in the catalog nor installed at the target system.

