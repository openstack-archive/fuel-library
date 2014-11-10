module Puppet
  newtype(:cs_colocation) do
    desc 'Type for manipulating corosync/pacemaker colocation.  Colocation
      is the grouping together of a set of primitives so that they travel
      together when one of them fails.  For instance, if a web server vhost
      is colocated with a specific ip address and the web server software
      crashes, the ip address with migrate to the new host with the vhost.

      More information on Corosync/Pacemaker colocation can be found here:

      * http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/_ensuring_resources_run_on_the_same_host.html'

    ensurable

    newparam(:name) do
      desc 'Identifier of the colocation entry. This value needs to be unique
        across the entire Corosync/Pacemaker configuration since it doesn\'t have
        the concept of name spaces per type.'
      isnamevar
    end

    newproperty(:primitives, :array_matching => :all) do
      desc 'Two Corosync primitives to be grouped together. Colocation groups
        come in twos.  Property will raise an error if
        you do not provide a two value array.'
    end

    newparam(:cib) do
      desc 'Corosync applies its configuration immediately. Using a CIB allows
        you to group multiple primitives and relationships to be applied at
        once. This can be necessary to insert complex configurations into
        Corosync correctly.

        This paramater sets the CIB this colocation should be created in. A
        cs_shadow resource with a title of the same name as this value should
        also be added to your manifest.'
    end

    newproperty(:score) do
      desc 'The priority of this colocation.  Primitives can be a part of
        multiple colocation groups and so there is a way to control which
        primitives get priority when forcing the move of other primitives.
        This value can be an integer but is often defined as the string
        INFINITY.'

      defaultto 'INFINITY'

      validate do |value|
        break if %w(inf INFINITY -inf -INFINITY).include? value
        break if value.to_i.to_s == value
        fail 'Score parameter is invalid, should be +/- INFINITY(or inf) or Integer'
      end

      munge do |value|
        value.gsub 'inf', 'INFINITY'
      end

      isrequired
    end

    autorequire(:cs_shadow) do
      [self[:cib]] if self[:cib]
    end

    autorequire(:service) do
      ['corosync']
    end

    autorequire(:cs_resource) do
      self[:primitives] if self[:primitives].is_a? Array
    end

    validate do
      break if self[:ensure] == :absent
      fail 'The primitives property must be a two value array' unless self[:primitives].is_a? Array and self[:primitives].size == 2
    end

  end
end
