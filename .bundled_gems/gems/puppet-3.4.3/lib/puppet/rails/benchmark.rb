require 'benchmark'
require 'yaml'

module Puppet::Rails::Benchmark
  $benchmarks = {:accumulated => {}}

  def time_debug?
    Puppet::Rails::TIME_DEBUG
  end

  def railsmark(message)
    result = nil
    seconds = Benchmark.realtime { result = yield }
    Puppet.debug(message + " in %0.2f seconds" % seconds)

    $benchmarks[message] = seconds if time_debug?
    result
  end

  def debug_benchmark(message)
    return yield unless Puppet::Rails::TIME_DEBUG

    railsmark(message) { yield }
  end

  # Collect partial benchmarks to be logged when they're
  # all done.
  #   These are always low-level debugging so we only
  # print them if time_debug is enabled.
  def accumulate_benchmark(message, label)
    return yield unless time_debug?

    $benchmarks[:accumulated][message] ||= Hash.new(0)
    $benchmarks[:accumulated][message][label] += Benchmark.realtime { yield }
  end

  # Log the accumulated marks.
  def log_accumulated_marks(message)
    return unless time_debug?

    return if $benchmarks[:accumulated].empty? or $benchmarks[:accumulated][message].nil? or $benchmarks[:accumulated][message].empty?

    $benchmarks[:accumulated][message].each do |label, value|
      Puppet.debug(message + ("(#{label})") + (" in %0.2f seconds" % value))
    end
  end

  def write_benchmarks
    return unless time_debug?

    branch = %x{git branch}.split("\n").find { |l| l =~ /^\*/ }.sub("* ", '')

    file = "/tmp/time_debugging.yaml"

    if Puppet::FileSystem::File.exist?(file)
      data = YAML.load_file(file)
    else
      data = {}
    end
    data[branch] = $benchmarks
    Puppet::Util.replace_file(file, 0644) { |f| f.print YAML.dump(data) }
  end
end
