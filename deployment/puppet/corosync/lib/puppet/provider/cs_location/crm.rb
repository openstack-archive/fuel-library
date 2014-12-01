require File.join File.dirname(__FILE__), '../corosync'
XML=File.join File.dirname(__FILE__), '1.xml'

Puppet::Type.type(:cs_location).provide(:crm, :parent => Puppet::Provider::Corosync) do
  desc 'Specific provider for a rather specific type since I currently have no plan to
        abstract corosync/pacemaker vs. keepalived.  This provider will check the state
        of current primitive colocations on the system; add, delete, or adjust various
        aspects.'

  # Path to the crm binary for interacting with the cluster configuration.
  # Decided to just go with relative.

  commands :cibadmin => 'cibadmin'
  commands :crm_shadow => 'crm_shadow'
  commands :crm => 'crm'
  commands :crm_diff => 'crm_diff'
  commands :crm_attribute => 'crm_attribute'

  def self.instances
    block_until_ready
    instances = []
    raw, status = dump_cib
    doc = REXML::Document.new(raw)

    doc.root.elements['configuration'].elements['constraints'].each_element('rsc_location') do |location_element|
      items = location_element.attributes
      rules = []
      node_name = nil
      node_score = nil

      if items['node']
        # node score based rule
        node_name  = items['node'].to_s
        node_score = items['score'].to_s
      elsif location_element.elements['rule']
        # custom rule
        location_element.each_element('rule') do |rule_element|
          # node score
          rule = {
            'boolean' => rule_element.attributes['boolean-op'].to_s || 'and',
            'score'   => rule_element.attributes['score'].to_s,
          }
          # expressions
          rule_element.each_element('expression') do |expression_element|
            #expr_id = expr.attributes['id']
            expression_structure = {}
            expression_element.attributes.each do |key, value|
              next if key == 'id'
              expression_structure[key.to_s] = value.to_s
            end
            rule['expressions'] = [] unless rule['expressions']
            rule['expressions'] << expression_structure
          end
          # date expressions
          rule_element.each_element('date_expression') do |date_expression_element|
            date_expression_structure = {
              'operation' => date_expression_element.attributes['operation'].to_s,
              'start'     => date_expression_element.attributes['start'].to_s,
              'end'       => date_expression_element.attributes['end'].to_s,
            }
            if date_expression_element.attributes['operation'] == 'date_spec'
              date_expression_structure['date_spec'] = date_expression_element.elements[1].attributes.reject { |key, value| key == 'id' }
            elsif date_expression_element.attributes['operation'] == 'in_range' and date_expression_element.elements['duration']
              date_expression_structure['duration'] = date_expression_element.elements[1].attributes.reject { |key, value| key == 'id' }
            end
            rule['date_expressions'] = [] unless rule['date_expressions']
            rule['date_expressions'] << date_expression_structure
          end

          rules << rule
        end

      end

      location_instance = {
        :name       => items['id'],
        :ensure     => :present,
        :primitive  => items['rsc'],
      }
      location_instance[:rules] = rules if rules.any?
      location_instance[:node_score] = node_score if node_score
      location_instance[:node_name] = node_name if node_name
      instances << new(location_instance)
    end
    instances
  end

  # Create just adds our resource to the property_hash and flush will take care
  # of actually doing the work.
  def create
    @property_hash = {
      :name       => @resource[:name],
      :ensure     => :present,
      :primitive  => @resource[:primitive],
      :node_name  => @resource[:node_name],
      :node_score => @resource[:node_score],
      :rules      => @resource[:rules],
      :cib        => @resource[:cib],
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    debug('Removing location')
    crm('configure', 'delete', @resource[:name])
    @property_hash.clear
  end

  # Getter that obtains the primitives array for us that should have
  # been populated by prefetch or instances (depends on if your using
  # puppet resource or not).
  def primitive
    @property_hash[:primitive]
  end

  # Getter that obtains the our score that should have been populated by
  # prefetch or instances (depends on if your using puppet resource or not).
  def node_score
    @property_hash[:node_score]
  end

  def rules
    @property_hash[:rules]
  end

  def node_name
    @property_hash[:node_name]
  end

  # Our setters for the primitives array and score.  Setters are used when the
  # resource already exists so we just update the current value in the property
  # hash and doing this marks it to be flushed.
  def rules=(should)
    @property_hash[:rules] = should
  end

  def primitives=(should)
    @property_hash[:primitive] = should
  end

  def node_score=(should)
    @property_hash[:node_score] = should
  end

  def node_name=(should)
    @property_hash[:node_name] = should
  end

  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.  It generates a temporary file with
  # the updates that need to be made.  The temporary file is then used
  # as stdin for the crm command.
  def flush
    unless @property_hash.empty?
      self.class.block_until_ready
      updated = 'location '
      updated << "#{@property_hash[:name]} #{@property_hash[:primitive]} "
      if @property_hash[:node_name]
        # node score rule
        debug "Rule for '#{@resource}': node: #{@property_hash[:node_name]} score: #{@property_hash[:node_score]}"
        updated << "#{@property_hash[:node_score]}: "
        updated << "#{@property_hash[:node_name]}"
      elsif @property_hash[:rules]
        # custom rule
        debug "Rule for '#{@resource}': #{@property_hash[:rules].inspect}"
        @property_hash[:rules].each do |rule_hash|
          updated << 'rule '
          updated << "$role = #{rule_hash['role']} " if rule_hash['role']
          updated << "#{rule_hash['score']}: "

          if rule_hash['expressions']
            rule_hash['expressions'].each do |expr|
              updated << "#{expr['attribute']} " if expr['attribute']
              updated << "#{expr['type']}:" if expr['type']
              updated << "#{expr['operation']} " if expr['operation']
              updated << "#{expr['value']} " if expr['value']
            end
          end

          if rule_hash['date_expressions']
            rule_hash['date_expressions'].each do |date_expr|
              updated << 'date '
              if date_expr['date_spec']
                updated << 'date_spec '
                date_expr['date_spec'].each{|key,value| updated << "#{key}=#{value} " }
              else
                updated << "#{date_expr['operation']} "
                if date_expr['operation'] == 'in_range'
                  updated << "start=#{date_expr['start']} "
                  if date_expr['duration'].nil?
                    updated << "end=#{date_expr['end']} "
                  else
                    date_expr['duration'].each do |key,value|
                      updated << "#{key}=#{value} "
                    end
                  end
                elsif date_expr['operation'] == 'gt'
                  updated << "#{date_expr['start']} "
                elsif date_expr[:operation] == 'lt'
                  updated << "#{date_expr['end']} "
                end
              end
            end
          end

          rule_number = 0
          rule_number += rule_hash['expressions'].size if rule_hash['expressions']
          rule_number += rule_hash['date_expressions'].size if rule_hash['date_expressions']
          updated << "#{rule_hash['boolean'].to_s} " if rule_number > 1
        end
      end

      debug "Creating location with command:\n #{updated}\n"

      #Tempfile.open('puppet_crm_update') do |tmpfile|
      #  tmpfile.write(updated.rstrip)
      #  tmpfile.flush
      #  apply_changes(@resource[:name],tmpfile,'location')
      #end
    end
  end
end