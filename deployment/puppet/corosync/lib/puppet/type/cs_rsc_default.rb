module Puppet
  newtype(:cs_rsc_default) do
    desc 'Type for manipulating corosync/pacemaker configuration rsc_defaults.
      Besides the configuration file that is managed by the module the contains
      all these related Corosync types and providers, there is a set of cluster
      rsc_defaults that can be set and saved inside the CIB (A CIB being a set of
      configuration that is synced across the cluster, it can be exported as XML
      for processing and backup).  The type is pretty simple interface for
      setting key/value pairs or removing them completely.  Removing them will
      result in them taking on their default value.

      More information on cluster properties can be found here:

      * http://clusterlabs.org/doc/en-US/Pacemaker/1.1-plugin/html/Clusters_from_Scratch/ch05s03s02.html'

    ensurable

    newparam(:name) do
      desc 'Name identifier of this rsc_defaults.  Simply the name of the cluster
        rsc_defaults.  Happily most of these are unique.'

      isnamevar
    end

    newparam(:cib) do
      desc 'Corosync applies its configuration immediately. Using a CIB allows
            you to group multiple primitives and relationships to be applied at
            once. This can be necessary to insert complex configurations into
            Corosync correctly.

            This paramater sets the CIB this order should be created in. A
            cs_shadow resource with a title of the same name as this value should
            also be added to your manifest.'
    end

    newproperty(:value) do
      desc "Value of the rsc_defaults.  It is expected that this will be a single
        value but we aren't validating string vs. integer vs. boolean because
        cluster rsc_resources can range the gambit."
    end

    autorequire(:service) do
      ['corosync']
    end

    autorequire(:cs_shadow) do
      [parameter(:cib).value] if parameter :cib
    end

    validate do
      break if parameter(:ensure) and parameter(:ensure).value == :absent
      fail 'Option "value" is required!' unless parameter :value
    end

  end
end
