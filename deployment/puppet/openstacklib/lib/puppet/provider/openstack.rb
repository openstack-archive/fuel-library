require 'csv'
require 'puppet'
require 'timeout'

class Puppet::Error::OpenstackAuthInputError < Puppet::Error
end

class Puppet::Error::OpenstackUnauthorizedError < Puppet::Error
end

class Puppet::Provider::Openstack < Puppet::Provider

  initvars # so commands will work
  commands :openstack_cmd => 'openstack'

  def self.openstack(*args)
    timeout_time = 10
    begin
      Timeout.timeout(timeout_time) do
        openstack_cmd *args
      end
    rescue Timeout::Error
      raise Puppet::ExecutionFailure, "Command: 'openstack #{args.join ' '}' has been running for more then #{timeout_time} seconds!"
    end
  end

  # Returns an array of hashes, where the keys are the downcased CSV headers
  # with underscores instead of spaces
  def self.request(service, action, properties, credentials=nil)
    env = credentials ? credentials.to_env : {}
    Puppet::Util.withenv(env) do
      rv = nil
      timeout = 60
      end_time = Time.now.to_i + timeout
      loop do
        begin
          if(action == 'list')
            response = openstack(service, action, '--quiet', '--format', 'csv', properties)
            response = parse_csv(response)
            keys = response.delete_at(0) # ID,Name,Description,Enabled
            rv = response.collect do |line|
              hash = {}
              keys.each_index do |index|
                key = keys[index].downcase.gsub(/ /, '_').to_sym
                hash[key] = line[index]
              end
              hash
            end
          elsif(action == 'show' || action == 'create')
            rv = {}
            # shell output is name="value"\nid="value2"\ndescription="value3" etc.
            openstack(service, action, '--format', 'shell', properties).split("\n").each do |line|
              # key is everything before the first "="
              key, val = line.split("=", 2)
              next unless val # Ignore warnings
              # value is everything after the first "=", with leading and trailing double quotes stripped
              val = val.gsub(/\A"|"\Z/, '')
              rv[key.downcase.to_sym] = val
            end
          else
            rv = openstack(service, action, properties)
          end
          break
        rescue Puppet::ExecutionFailure => e
          raise(Puppet::Error::OpenstackUnauthorizedError, 'Could not authenticate.') if e.message =~ /HTTP 401/
          current_time = Time.now.to_i
          raise e if current_time > end_time
          Puppet::debug("Non-fatal error: '#{e.message}'; retrying for #{end_time - current_time} more seconds.")
          sleep 2
          retry
        end
      end
      debug "OpenStack request: '#{service} #{action} #{properties}' returned: '#{rv.inspect}'"
      return rv
    end
  end

  private

  def self.parse_csv(text)
    # Ignore warnings - assume legitimate output starts with a double quoted
    # string.  Errors will be caught and raised prior to this
    text = text.split("\n").drop_while { |line| line !~ /^\".*\"/ }.join("\n")
    return CSV.parse(text + "\n")
  end
end
