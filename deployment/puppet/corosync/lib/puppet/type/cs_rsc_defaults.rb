module Puppet
  newtype(:cs_rsc_defaults) do
    @doc = "Type for manipulating corosync/pacemaker configuration rsc_defaults.
      Besides the configuration file that is managed by the module the contains
      all these related Corosync types and providers, there is a set of cluster
      rsc_defaults that can be set and saved inside the CIB (A CIB being a set of
      configuration that is synced across the cluster, it can be exported as XML
      for processing and backup).  The type is pretty simple interface for
      setting key/value pairs or removing them completely.  Removing them will
      result in them taking on their default value.

      More information on cluster properties can be found here:

      * http://clusterlabs.org/doc/en-US/Pacemaker/1.1-plugin/html/Clusters_from_Scratch/ch05s03s02.html"

    ensurable

    newparam(:name) do
      desc "Name identifier of this rsc_defaults.  Simply the name of the cluster
        rsc_defaults.  Happily most of these are unique."

      isnamevar
    end

    newproperty(:value) do
      desc "Value of the rsc_defaults.  It is expected that this will be a single
        value but we aren't validating string vs. integer vs. boolean because
        cluster rsc_resources can range the gambit."
    end

    autorequire(:service) do
      [ 'corosync' ]
    end
  end
end
