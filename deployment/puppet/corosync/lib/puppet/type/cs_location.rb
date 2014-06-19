module Puppet
  newtype(:cs_location) do
    @doc = "Type for manipulating corosync/pacemaker location.  Location
      is the set of rules defining the place where resource will be run.
      More information on Corosync/Pacemaker location can be found here:
      * http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/_ensuring_resources_run_on_the_same_host.html"

    ensurable

    newparam(:name) do
      desc "Identifier of the location entry.  This value needs to be unique
        across the entire Corosync/Pacemaker configuration since it doesn't have
        the concept of name spaces per type."
      isnamevar
    end

    newproperty(:primitive) do
      desc "Corosync primitive being managed."
      isrequired
    end

    newparam(:cib) do
      desc "Corosync applies its configuration immediately. Using a CIB allows
        you to group multiple primitives and relationships to be applied at
        once. This can be necessary to insert complex configurations into
        Corosync correctly.

        This paramater sets the CIB this location should be created in. A
        cs_shadow resource with a title of the same name as this value should
        also be added to your manifest."
    end

    newproperty(:node_score) do
      desc "The score for the node"

      validate do |value|
        begin
          if  value !~ /^([+-]){0,1}(inf|INFINITY)$/
            score = Integer(value)
          end
        rescue ArgumentError
          raise Puppet::Error("score parameter is invalid, should be +/- INFINITY(or inf) or Integer")
        end
      end
    end

    newproperty(:rules, :array_matching=>:all) do
      desc "Specify rules for location"
      munge do |rule|
        convert_to_sym(rule)
      end
    end

    newproperty(:node_name) do
      desc "The node for which to apply node_score"
    end

    autorequire(:cs_shadow) do
      rv = []
      rv << @parameters[:cib].value if !@parameters[:cib].nil?
      rv
    end

    autorequire(:service) do
      [ 'corosync' ]
    end

    autorequire(:cs_resource) do
      [ @parameters[:primitive].value ]
    end

  end
end

def convert_to_sym(hash)
  if hash.is_a? Hash
    hash.inject({}) do |memo,(key,value)|
      value = convert_to_sym(value)
      if value.is_a?(Array)
        value.collect! do |arr_el|
          convert_to_sym(arr_el)
        end
      end
      memo[key.to_sym] = value
      memo
    end
  else
    hash
  end
end

