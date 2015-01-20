module Puppet
  newtype(:cs_group) do
    @doc = "Type for manipulating Corosync/Pacemkaer group entries.
      Groups are a set or resources (primitives) that need to be
      grouped together.

      More information can be found at the following link:

      * http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Pacemaker_Explained/ch-advanced-resources.html#group-resources"

    ensurable

    newparam(:name) do
      desc "Name identifier of this group entry.  This value needs to be unique
        across the entire Corosync/Pacemaker configuration since it doesn't have
        the concept of name spaces per type."
      isnamevar
    end

    newproperty(:primitives, :array_matching => :all) do
      desc "An array of primitives to have in this group.  Must be listed in the
          order that you wish them to start."

      # Have to redefine should= here so we can sort the array that is given to
      # us by the manifest.  While were checking on the class of our value we
      # are going to go ahead and do some validation too.  The way Corosync
      # colocation works we need to only accept two value arrays.
      def should=(value)
        super
        raise Puppet::Error, "Puppet::Type::Cs_Group: primitives property must be at least a 2-element array." unless value.is_a? Array and value.length > 1
        @should
      end
    end

    newparam(:cib) do
      desc "Corosync applies its configuration immediately. Using a CIB allows
        you to group multiple primitives and relationships to be applied at
        once. This can be necessary to insert complex configurations into
        Corosync correctly.

        This paramater sets the CIB this order should be created in. A
        cs_shadow resource with a title of the same name as this value should
        also be added to your manifest."
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
