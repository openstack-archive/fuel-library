require 'find'

def files_dir
  return $files_dir if $files_dir
  $files_dir = File.join File.dirname(__FILE__), '..', 'files'
end

def puppet_dir
  return $puppet_dir if $puppet_dir
  $puppet_dir = File.join File.dirname(__FILE__), '..', 'deployment', 'puppet'
end

def for_files_dir_all_files
  Find.find(files_dir) do |file|
    next unless File.file? file
    yield file
  end
end

def find_file_in_puppet_dir(files_file_path)
  files_file_name = File.basename files_file_path
  found = []
  Find.find(puppet_dir) do |puppet_file_path|
    next unless File.file? puppet_file_path
    next unless puppet_file_path.include? '/files/'
    puppet_file_name = File.basename puppet_file_path
    next unless puppet_file_name == files_file_name
    found << [puppet_file_path, files_equal?(puppet_file_path, files_file_path)]
  end
  found
end

def files_equal?(file1, file2)
  begin
    file1_data = File.read file1
    file2_data = File.read file2
    file1_data == file2_data
  rescue
    false
  end
end

for_files_dir_all_files do |files_file_path|
  puppet_files = find_file_in_puppet_dir files_file_path
  if puppet_files.length > 1
    puts "More the one file found! #{files_file_path.inspect}"
    next
  end
  if puppet_files.any?
    puppet_file_path, equal = puppet_files.first
    next if equal
    puts "Copy: '#{puppet_file_path}' to: '#{files_file_path}'"
    system "cp '#{puppet_file_path}' '#{files_file_path}'"
  end
end

