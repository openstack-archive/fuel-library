class Noop
  module Coverage

    def coverage_base_dir
      return @coverage_base_dir if @coverage_base_dir
      @coverage_base_dir = File.expand_path File.join(spec_path, '..', '..', 'coverage')
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
        SimpleCov.result.format!
        puts "Total coverage percent: #{SimpleCov.result.covered_percent.round 2}"
      end
    end

  end
  extend Coverage
end
