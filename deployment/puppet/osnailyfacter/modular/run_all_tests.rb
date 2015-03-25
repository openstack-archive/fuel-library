# Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

require 'find'
require 'yaml'

# this file can run all the tests fro the modular tasks found
# in this folder and then display the report

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

############################################

run_tests

#TODO port the old tasklib for this tests format

