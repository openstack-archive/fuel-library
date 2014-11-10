module Puppet
  newtype(:cs_location) do
    @doc = 'Type for manipulating corosync/pacemaker location.  Location
      is the set of rules defining the place where resource will be run.
      More information on Corosync/Pacemaker location can be found here:
      * http://www.clusterlabs.org/doc/en-US/Pacemaker/1.1/html/Clusters_from_Scratch/_ensuring_resources_run_on_the_same_host.html'

    ensurable

    newparam(:name) do
      desc 'Identifier of the location entry.  This value needs to be unique
        across the entire Corosync/Pacemaker configuration since it doesn\'t have
        the concept of name spaces per type.'
      isnamevar
    end

    newproperty(:primitive) do
      desc 'Corosync primitive being managed.'
    end

    newparam(:cib) do
      desc 'Corosync applies its configuration immediately. Using a CIB allows
        you to group multiple primitives and relationships to be applied at
        once. This can be necessary to insert complex configurations into
        Corosync correctly.

        This paramater sets the CIB this location should be created in. A
        cs_shadow resource with a title of the same name as this value should
        also be added to your manifest.'
    end

    newproperty(:node_score) do
      desc 'The score for the node'

      validate do |value|
        break if %w(inf INFINITY -inf -INFINITY).include? value
        break if value.to_i.to_s == value
        fail 'Score parameter is invalid, should be +/- INFINITY(or inf) or Integer'
      end

      munge do |value|
        value.gsub 'inf', 'INFINITY'
      end
    end

    newproperty(:rules, :array_matching => :all) do
      desc 'Specify rules for location'

      munge do |rule|
        stringify rule
        if @rule_number
          @rule_number += 1
        else
          @rule_number = 0
        end
        munge_rule rule, @rule_number, @resource[:name]
      end
    end

    newproperty(:node_name) do
      desc 'The node for which to apply node_score'
    end

    autorequire(:cs_shadow) do
      [parameter(:cib).value] if parameter :cib
    end

    autorequire(:service) do
      ['corosync']
    end

    autorequire(:cs_resource) do
      [parameter(:primitive).value] if parameter :primitive
    end

    validate do
      fail 'Primitive name is required!' unless parameter :primitive
      unless (parameter(:rules) and parameter(:rules).value.is_a? Array and parameter(:rules).value.any?) or
          (parameter :node_score and parameter :node_name)
        fail 'You need either rules or node name and score!'
      end
    end

  end
end

# convert data structure to strings
def stringify(data)
  if data.is_a? Hash
    new_data = {}
    data.each do |key, value|
      new_data.store stringify(key), stringify(value)
    end
    data.clear
    data.merge! new_data
  elsif data.is_a? Array
    data.map! do |element|
      stringify element
    end
  else
    data.to_s
  end
end

def munge_rule(rule, rule_number, title)
  rule['id'] = "#{title}-rule-#{rule_number}" unless rule['id']
  rule['boolean-op'] = 'or' unless rule['boolean-op']
  rule['score'].gsub! 'inf', 'INFINITY' if rule['score']
  if rule['expressions']
    unless rule['expressions'].is_a? Array
      expressions_array = []
      expressions_array << rule['expressions']
      rule['expressions'] = expressions_array
    end
    expression_number = 0
    rule['expressions'].each do |expression|
      unless expression['id']
        expression['id'] = "#{title}-rule-#{rule_number}-expression-#{expression_number}"
      end
      expression_number += 1
    end
  end
  rule
end