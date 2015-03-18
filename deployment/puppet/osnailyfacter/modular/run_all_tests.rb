require 'find'
require 'yaml'

def test_dir
  File.dirname(__FILE__)
end

def each_task_file
  Find.find(test_dir) do |path|
    yield path if path.end_with? 'tasks.yaml'
  end
end

def tasks
  data = []
  each_task_file do |file|
    begin
      task = YAML.load_file file
      data = data + task if task.is_a? Array
    rescue => e
      puts "Error in task file '#{file}': #{e.message}"
      next
    end
  end
  data
end

def each_test
  tasks.each do |task|
    next unless task.is_a? Hash
    id = task['id']
    next unless id
    test_pre = task.fetch('test_pre', {}).fetch('cmd', nil)
    test_post = task.fetch('test_post', {}).fetch('cmd', nil)
    yield id, :pre, test_pre if test_pre
    yield id, :post, test_post if test_post
  end
end

def print_results(results)
  results.each do |result|
    id = result[:id].to_s.ljust 30
    type = result[:type].to_s.ljust 4
    success = (result[:success] ? 'OK' : 'FAIL').ljust 4
    cmd = result[:cmd]
    puts "#{id} #{type} #{success} '#{cmd}'"
  end
end

def run_tests
  results = []
  each_test do |id, type, cmd|
    puts '=' * 79
    puts "Run: '#{cmd}'"
    system cmd
    success = $?.exitstatus == 0
    result = {
        :id => id,
        :cmd => cmd,
        :type => type,
        :success => success,
    }
    results << result
  end
  puts '=' * 79
  print_results results
end

run_tests
