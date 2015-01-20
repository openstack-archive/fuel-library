module Puppet
  newtype(:cs_colocation) do
    @doc = "Type for manipulating corosync/pacemaker colocation.  Colocation
      is the grouping together of a set of primitives so that they travel
      together when one of them fails.  For instance, if a web server vhost
      is colocated with a specific ip address and the web server software
      crashes, the ip address with migrate to the new host with the vhost.

      More information on Corosync/Pacemaker colocation can be found here:

      * http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/_ensuring_resources_run_on_the_same_host.html"

    ensurable

    newparam(:name) do
      desc "Identifier of the colocation entry.  This value needs to be unique
        across the entire Corosync/Pacemaker configuration since it doesn't have
        the concept of name spaces per type."

      isnamevar
    end

    newproperty(:primitives, :array_matching => :all) do
      desc "Two Corosync primitives to be grouped together.  Colocation groups
        come in twos and order is irrelavent.  Property will raise an error if
        you do not provide a two value array."

      # Have to redefine should= here so we can sort the array that is given to
      # us by the manifest.  While were checking on the class of our value we
      # are going to go ahead and do some validation too.  The way Corosync
      # colocation works we need to only accept two value arrays.
      def should=(value)
        super
        if value.is_a? Array
          raise Puppet::Error, "Puppet::Type::Cs_Colocation: The primitives property must be a two value array." unless value.size >= 2
          @should.sort!
        else
          raise Puppet::Error, "Puppet::Type::Cs_Colocation: The primitives property must be a two value array."
          @should
        end
      end
    end

    newparam(:cib) do
      desc "Corosync applies its configuration immediately. Using a CIB allows
        you to group multiple primitives and relationships to be applied at
        once. This can be necessary to insert complex configurations into
        Corosync correctly.

        This paramater sets the CIB this colocation should be created in. A
        cs_shadow resource with a title of the same name as this value should
        also be added to your manifest."
    end

    newproperty(:score) do
      desc "The priority of this colocation.  Primitives can be a part of
        multiple colocation groups and so there is a way to control which
        primitives get priority when forcing the move of other primitives.
        This value can be an integer but is often defined as the string
        INFINITY."

        defaultto 'INFINITY'
    end

    autorequire(:cs_shadow) do
      [ @parameters[:cib] ]
    end

    autorequire(:service) do
      [ 'corosync' ]
    end

    autorequire(:cs_primitive) do
      autos = []
      @parameters[:primitives].should.each do |val|
        autos << unmunge_cs_primitive(val)
      end

      autos
    end

    def unmunge_cs_primitive(name)
      name = name.split(':')[0]
      if name.start_with? 'ms_'
        name = name[3..-1]
      end

      name
    end
  end
end
