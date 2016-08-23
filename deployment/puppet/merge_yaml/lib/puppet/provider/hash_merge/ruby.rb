require 'yaml'
require 'json'

Puppet::Type.type(:hash_merge).provide(:ruby) do
  attr_accessor :resource

  # The path to the file
  # @return [String]
  def file_path
    resource[:path]
  end

  # What serializer does the file use?
  # @return [Symbol]
  def file_type
    resource[:type]
  end

  # Check if the file exists
  # @return [true,false]
  def file_exists?
    File.exist? file_path
  end

  # Serialize the data and write it to the file
  # @param data [Hash]
  def write_data_to_file(data)
    content = nil
    if file_type == :yaml
      content = YAML.dump(data)
    elsif file_type == :json
      content = JSON.dump(data)
    end
    write_file content
  end

  # Write the content to the file
  # @param data [Hash]
  def write_file(data)
    File.open(file_path, 'w') do |file|
      file.puts data
    end
  end

  # Read the file and return its content
  # @return [String,nil]
  def read_file
    return nil unless file_exists?
    begin
      File.read file_path
    rescue Exception => exception
      warn "Could not read the file: '#{file_path}': #{exception}"
      return nil
    end
  end

  # Read the file and parse the data
  # @return [Hash]
  def read_data_from_file
    content = read_file
    return nil unless content
    data = nil
    if file_type == :yaml
      begin
        data = YAML.load(content)
      rescue Exception => exception
        warn "Could not parse the YAML file: '#{file_path}': #{exception}"
        return nil
      end
    elsif file_type == :json
      begin
        data = JSON.parse(content)
      rescue Exception => exception
        warn "Could not parse the JSON file: '#{file_path}': #{exception}"
        return nil
      end
    end
    data
  end

  #####

  # @return [true,false]
  def exists?
    debug 'Call: exists?'
    file_exists?
  end

  def create
    debug 'Call: create'
    write_data_to_file resource[:data]
  end

  def destroy
    debug 'Call: destroy'
    File.unlink file_path
  end

  def data
    debug 'Call: data'
    read_data_from_file
  end

  # @return [Hash]
  def data=(data)
    debug "Call: data=(#{data.class}/#{data.object_id})"
    write_data_to_file data
  end

end
