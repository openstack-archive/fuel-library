require 'rexml/document'
require 'rexml/formatters/pretty'
require 'timeout'
require 'yaml'

require File.join File.dirname(__FILE__), 'cib'
require File.join File.dirname(__FILE__), 'constraints'
require File.join File.dirname(__FILE__), 'helpers'
require File.join File.dirname(__FILE__), 'options'
require File.join File.dirname(__FILE__), 'primitives'
require File.join File.dirname(__FILE__), 'properties'
require File.join File.dirname(__FILE__), 'report'
require File.join File.dirname(__FILE__), 'resource_defaults'
require File.join File.dirname(__FILE__), 'status'
require File.join File.dirname(__FILE__), 'wait'
require File.join File.dirname(__FILE__), 'xml'

class Puppet::Provider::Pacemaker < Puppet::Provider

  include ::Pacemaker::Cib
  include ::Pacemaker::Constraints
  include ::Pacemaker::Helpers
  include ::Pacemaker::Options
  include ::Pacemaker::Primitives
  include ::Pacemaker::Properties
  include ::Pacemaker::Report
  include ::Pacemaker::Resource_defaults
  include ::Pacemaker::Status
  include ::Pacemaker::Wait
  include ::Pacemaker::Xml

  def initialize(*args)
    cib_reset
    super
  end

  # reset all saved variables to obtain new data
  def cib_reset
    @raw_cib = nil
    @cib_file = nil
    @cib = nil
    @primitives = nil
    @primitives_structure = nil
    @locations_structure = nil
    @colocations_structure = nil
    @orders_structure = nil
    @nodes_structure = nil
  end

end

# TODO: groups
# TODO: op_defaults
# TODO: split to subfiles
# TODO: resource <-> constraint autorequire/autobefore
# TODO: constraint fail is resource missing
# TODO: resource refuse to delete if constrains present or remove them too
# TODO: refactor status-metadata processing
# TODO: refactor options
# TODO: options and rules arrays sort? sets?
# TODO: should_to_s and is_to_s for array/hash params of some types
# TODO: xml elements should have __crm_diff_marker__="added:top"
