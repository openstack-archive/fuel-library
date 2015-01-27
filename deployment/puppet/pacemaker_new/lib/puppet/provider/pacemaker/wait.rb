module Pacemaker
  module Wait
    # retry the given command until it runs without errors
    # or for RETRY_COUNT times with RETRY_STEP sec step
    # print cluster status report on fail
    # @param options [Hash]
    def retry_block(options = {})
      options = pacemaker_options.merge options

      options[:retry_count].times do
        begin
          out = Timeout::timeout(options[:retry_timeout]) { yield }
          if options[:retry_false_is_failure]
            return out if out
          else
            return out
          end
        rescue => e
          Puppet.debug "Execution failure: #{e.message}"
        end
        sleep options[:retry_step]
      end
      fail "Execution timeout after #{options[:retry_count] * options[:retry_step]} seconds!" if options[:retry_fail_on_timeout]
    end

    # wait for pacemaker to become online
    def wait_for_online
      debug "Waiting #{pacemaker_options[:retry_count] * pacemaker_options[:retry_step]} seconds for Pacemaker to become online"
      retry_block { is_online? }
      debug 'Pacemaker is online'
    end

    # wait until a primitive has known status
    # @param primitive [String] primitive name
    def wait_for_status(primitive, node = nil)
      message = "Wait for a known status of '#{primitive}'"
      message += " on node '#{node}'" if node
      debug message
      retry_block do
        cib_reset
        primitive_status(primitive) != nil
      end
      message = "Primitive '#{primitive}' has status '#{primitive_status primitive}'"
      message += " on node '#{node}'" if node
      debug message
    end

    # wait for primitive to start
    # if node is given then start on this node
    # @param primitive [String] primitive id
    # @param node [String] on this node if given
    def wait_for_start(primitive, node = nil)
      message = "Waiting #{pacemaker_options[:retry_count] * pacemaker_options[:retry_step]} seconds for service '#{primitive}' to start"
      message += " on node '#{node}'" if node
      debug message
      retry_block do
        cib_reset
        primitive_is_running? primitive, node
      end
      message = "Service '#{primitive}' have started"
      message += " on node '#{node}'" if node
      debug message
    end

    # wait for primitive to start as a master
    # if node is given then start as a master on this node
    # @param primitive [String] primitive id
    # @param node [String] on this node if given
    def wait_for_master(primitive, node = nil)
      message = "Waiting #{pacemaker_options[:retry_count] * pacemaker_options[:retry_step]} seconds for service '#{primitive}' to start master"
      message += " on node '#{node}'" if node
      debug message
      retry_block do
        cib_reset
        primitive_has_master_running? primitive, node
      end
      message = "Service '#{primitive}' have started master"
      message += " on node '#{node}'" if node
      debug message
    end

    # wait for primitive to stop
    # if node is given then start on this node
    # @param primitive [String] primitive id
    # @param node [String] on this node if given
    def wait_for_stop(primitive, node = nil)
      message = "Waiting #{pacemaker_options[:retry_count] * pacemaker_options[:retry_step]} seconds for service '#{primitive}' to stop"
      message += " on node '#{node}'" if node
      debug message
      retry_block do
        cib_reset
        result = primitive_is_running? primitive, node
        result.is_a? FalseClass
      end
      message = "Service '#{primitive}' was stopped"
      message += " on node '#{node}'" if node
      debug message
    end

    # check if pacemaker is online and we can work with it
    # pacemaker is online if cib can be downloaded
    # and DC have been designated
    # @return [TrueClass,FalseClass]
    def is_online?
      begin
        Timeout::timeout(pacemaker_options[:retry_timeout]) do
          dc_version = crm_attribute '-q', '--type', 'crm_config', '--query', '--name', 'dc-version'
          return false unless dc_version
          return false if dc_version.empty?
          return false unless dc
          return false unless cib_section_nodes_state
          true
        end
      rescue Puppet::ExecutionFailure => e
        debug "Offline: #{e.message}"
        false
      rescue Timeout::Error
        debug 'Online check timeout!'
        false
      end
    end

    # get the name of the DC node
    # @return [String, nil]
    def dc
      cib_element = cib.elements['/cib']
      return unless cib_element
      dc_node = cib_element.attribute('dc-uuid')
      return unless dc_node
      return if dc_node == 'NONE'
      dc_node.to_s
    end
  end
end
