class Noop
  module Coverage

    def coverage_base_dir
      return @coverage_base_dir if @coverage_base_dir
      @coverage_base_dir = File.expand_path File.join(spec_dir, '..', '..', 'coverage')
    end

    def coverage_prepare
      FileUtils.mkdir_p coverage_base_dir unless File.directory? coverage_base_dir
    end

    def coverage_simplecov
      coverage_prepare
      require 'simplecov'
      SimpleCov.start do
        SimpleCov.coverage_dir coverage_base_dir
        SimpleCov.use_merging
        SimpleCov.merge_timeout 7200
      end

      SimpleCov.at_exit do
        puts "-"*80
        puts "SimpleCov Coverage Report"
        SimpleCov.result.format!
        puts "Total coverage percent: #{SimpleCov.result.covered_percent.round 2}"
        puts "-"*80
      end
    end

    def coverage_rspec(file_name)
      coverage_prepare
      # capture the rspec coverage report
      puppet_coverage_report = capture_stdout do
        RSpec::Puppet::Coverage.report!
      end
      # write the rspec coverage report out to a file
      File.open("#{coverage_base_dir}/#{file_name}", "w") { |file|
        file.write(puppet_coverage_report.string)
      }
      # also print it out to the console
      puts "-"*80
      puts "RSpec Coverage Report for #{file_name}"
      puts puppet_coverage_report.string
      puts "-"*80
    end

  end
  extend Coverage
end
