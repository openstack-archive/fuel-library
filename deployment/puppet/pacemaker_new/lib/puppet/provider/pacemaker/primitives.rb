module Pacemaker
  module Primitives
    # sets the meta attribute of a primitive
    # @param primitive [String] primitive's id
    # @param attribute [String] atttibute's name
    # @param value [String] attribute's value
    def set_primitive_meta_attribute(primitive, attribute, value)
      options = ['--quiet', '--resource', primitive]
      options += ['--set-parameter', attribute, '--meta', '--parameter-value', value]
      retry_block { crm_resource options }
    end

    # disable this primitive
    # @param primitive [String] what primitive to disable
    def disable_primitive(primitive)
      set_primitive_meta_attribute primitive, 'target-role', 'Stopped'
    end

    alias :stop_primitive :disable_primitive

    # enable this primitive
    # @param primitive [String] what primitive to enable
    def enable_primitive(primitive)
      set_primitive_meta_attribute primitive, 'target-role', 'Started'
    end

    alias :start_primitive :enable_primitive

    # manage this primitive
    # @param primitive [String] what primitive to manage
    def manage_primitive(primitive)
      set_primitive_meta_attribute primitive, 'is-managed', 'true'
    end

    # unamanage this primitive
    # @param primitive [String] what primitive to unmanage
    def unmanage_primitive(primitive)
      set_primitive_meta_attribute primitive, 'is-managed', 'false'
    end

    # ban this primitive
    # @param primitive [String] what primitive to ban
    # @param node [String] on which node this primitive should be banned
    def ban_primitive(primitive, node)
      options = ['--quiet', '--resource', primitive, '--node', node]
      options += ['--ban']
      retry_block { crm_resource options }
    end

    # unban this primitive
    # @param primitive [String] what primitive to unban
    # @param node [String] on which node this primitive should be unbanned
    def unban_primitive(primitive, node)
      options = ['--quiet', '--resource', primitive, '--node', node]
      options += ['--clear']
      retry_block { crm_resource options }
    end

    alias :clear_primitive :unban_primitive

    # move this primitive
    # @param primitive [String] what primitive to un-move
    # @param node [String] to which node the primitive should be moved
    def move_primitive(primitive, node)
      options = ['--quiet', '--resource', primitive, '--node', node]
      options += ['--move']
      retry_block { crm_resource options }
    end

    # un-move this primitive
    # @param primitive [String] what primitive to un-move
    # @param node [String] from which node the primitive should be un-moved
    def unmove_primitive(primitive, node)
      options = ['--quiet', '--resource', primitive, '--node', node]
      options += ['--un-move']
      retry_block { crm_resource options }
    end

    # cleanup this primitive
    # @param primitive [String] what primitive to cleanup
    # @param node [String] on which node to cleanup (optional)
    # cleanups on every node if node is not given
    def cleanup_primitive(primitive, node = nil)
      options = ['--quiet', '--resource', primitive]
      options += ['--node', node] if node
      options += ['--cleanup']
      retry_block { crm_resource options }
    end

    ##############################################################################

    # get primitives configuration structure with primitives and their attributes
    # @return [Hash<String => Hash>]
    def primitives
      return @primitives_structure if @primitives_structure
      @primitives_structure = {}
      cib_section_primitives.each do |primitive|
        primitive_structure = {}
        id = primitive.attributes['id']
        next unless id
        primitive_structure.store 'name', id
        primitive.attributes.each do |k, v|
          primitive_structure.store k.to_s, v
        end

        if primitive.parent.name and primitive.parent.attributes['id']
          complex_structure = {
              'id' => primitive.parent.attributes['id'],
              'type' => primitive.parent.name
          }

          complex_meta_attributes = primitive.parent.elements['meta_attributes']
          if complex_meta_attributes
            complex_meta_attributes_structure = children_elements_to_hash complex_meta_attributes, 'name', 'nvpair'
            complex_structure.store 'meta_attributes', complex_meta_attributes_structure
          end

          primitive_structure.store 'name', complex_structure['id']
          primitive_structure.store 'complex', complex_structure
        end

        instance_attributes = primitive.elements['instance_attributes']
        if instance_attributes
          instance_attributes_structure = children_elements_to_hash instance_attributes, 'name', 'nvpair'
          primitive_structure.store 'instance_attributes', instance_attributes_structure
        end

        meta_attributes = primitive.elements['meta_attributes']
        if meta_attributes
          meta_attributes_structure = children_elements_to_hash meta_attributes, 'name', 'nvpair'
          primitive_structure.store 'meta_attributes', meta_attributes_structure
        end

        operations = primitive.elements['operations']
        if operations
          operations_structure = children_elements_to_hash operations, 'id', 'op'
          primitive_structure.store 'operations', operations_structure
        end

        @primitives_structure.store id, primitive_structure
      end
      @primitives_structure
    end

    # check if primitive exists in the confiuguration
    # @param primitive primitive id or name
    def primitive_exists?(primitive)
      primitives.key? primitive
    end

    # return primitive class
    # @param primitive [String] primitive id
    # @return [String] primitive class
    def primitive_class(primitive)
      return unless primitive_exists? primitive
      primitives[primitive]['class']
    end

    # return primitive type
    # @param primitive [String] primitive id
    # @return [String] primitive type
    def primitive_type(primitive)
      return unless primitive_exists? primitive
      primitives[primitive]['type']
    end

    # return the full name of the complex primitive
    # or just a name for a simple primitive
    # @return [String] primitive type
    def primitive_full_name(primitive)
      return unless primitive_exists? primitive
      primitives[primitive]['name']
    end

    # check if primitive is clone or multistate
    # @param primitive [String] primitive id
    # @return [TrueClass,FalseClass]
    def primitive_is_complex?(primitive)
      return unless primitive_exists? primitive
      primitives[primitive].key? 'complex'
    end

    # check if primitive is clone
    # @param primitive [String] primitive id
    # @return [TrueClass,FalseClass]
    def primitive_is_clone?(primitive)
      is_complex = primitive_is_complex? primitive
      return is_complex unless is_complex
      primitives[primitive]['complex']['type'] == 'clone'
    end

    # check if primitive is multistate
    # @param primitive [String] primitive id
    # @return [TrueClass,FalseClass]
    def primitive_is_multistate?(primitive)
      is_complex = primitive_is_complex? primitive
      return is_complex unless is_complex
      primitives[primitive]['complex']['type'] == 'master'
    end

    # determine if primitive is managed
    # @param primitive [String] primitive id
    # @return [TrueClass,FalseClass]
    def primitive_is_managed?(primitive)
      return unless primitive_exists? primitive
      is_managed = primitives.fetch(primitive).fetch('meta_attributes', {}).fetch('is-managed', {}).fetch('value', 'true')
      is_managed == 'true'
    end

    # determine if primitive has target-state started
    # @param primitive [String] primitive id
    # @return [TrueClass,FalseClass]
    def primitive_is_started?(primitive)
      return unless primitive_exists? primitive
      target_role = primitives.fetch(primitive).fetch('meta_attributes', {}).fetch('target-role', {}).fetch('value', 'Started')
      target_role == 'Started'
    end
  end
end
