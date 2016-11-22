#!/usr/bin/env ruby

require 'hiera'

class PluginsPull
  # The path to the hiera config
  # @return [String]
  def hiera_config
    '/etc/hiera.yaml'
  end

  # The Hiera object
  # @return [Hiera]
  def hiera_object
    return @hiera_object if @hiera_object
    @hiera_object = Hiera.new(:config => hiera_config)
    Hiera.logger = 'noop'
    @hiera_object
  end

  # @return [Object]
  def hiera_lookup(key, default = nil, scope = {}, order_override=[], resolution_type = :priority)
    hiera_object.lookup key.to_s, default, scope, order_override, resolution_type
  end

  # @param [String] message
  def output(message)
    puts message
  end

  # @param [String] message
  def warning(message)
    output "WARNING: #{message}"
  end

  # @param [String] message
  def error(message)
    output "ERROR: #{message}"
    exit 1
  end

  # @return [Array]
  def plugins
    return @plugins if @plugins
    @plugins = hiera_lookup 'plugins', [], {}, [], :priority
  end

  # @param [Array<String>] cmd
  # @return [true,false]
  def run(*cmd)
    output "RUN: #{cmd.join ' '}"
    system *cmd
    $?.exitstatus == 0
  end

  # The main function
  def main
    plugins.each do |plugin|
      unless plugin['scripts'].is_a? Array and plugin['name']
        warning "There is no 'script' and 'name' data for the plugin: #{plugin.inspect}. Skipping it!"
        next
      end

      name = plugin['name']

      output "Processing plugin: #{name}"

      plugin['scripts'].each do |script|
        local_path = script['local_path']
        remote_url = script['remote_url']

        unless local_path and remote_url
          warning "There is no 'local_path' or 'remote_url' for the plugin: #{plugin.inspect}. Skipping it!"
          next
        end

        local_path += '/' unless local_path.end_with? '/'
        remote_url += '/' unless remote_url.end_with? '/'

        output "Sync plugin: '#{name}' puppet from: '#{remote_url}' to: '#{local_path}'"

        run 'mkdir', '-p', local_path

        # Alternative method
        # run 'rsync', '-a', '-v', '--delete', '--exclude', '/deployment_scripts', remote_url, "#{remote_url}../", local_path

        success = run 'rsync', '-a', '-v', '--delete', '--filter', 'protect *.yaml', remote_url, local_path
        error "RSync of the plugin: '#{name}' have failed!" unless success
        run 'rsync', '-a', '-v', "#{remote_url}../*.yaml", local_path
      end
    end
  end

end

if __FILE__ == $0
  PluginsPull.new.main
end
