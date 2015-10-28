module Noop::Coverage

  # def coverage_prepare
  #   require 'simplecov'
  #   SimpleCov.start do
  #     SimpleCov.coverage_dir("coverage")
  #     SimpleCov.use_merging
  #     SimpleCov.merge_timeout(7200)
  #   end
  # end
  #
  # def coverage_report
  #   puppet_coverage_report = StringIO.new
  #   $stdout = puppet_coverage_report
  #   RSpec::Puppet::Coverage.report!
  #   report_file = "coverage/#{astute_yaml_name}"
  #   File.open(report_file, 'w') { |file| file.write($stdout.string) }
  #   puts $stdout.string
  # end

end
