require 'erb'
require 'stringio'

module PuppetSyntax
  class Templates
    def check(filelist)
      raise "Expected an array of files" unless filelist.is_a?(Array)

      # We now have to redirect STDERR in order to capture warnings.
      $stderr = warnings = StringIO.new()
      errors = []

      filelist.each do |erb_file|
        begin
          erb = ERB.new(File.read(erb_file), nil, '-')
          erb.filename = erb_file
          erb.result
        rescue NameError
          # This is normal because we don't have the variables that would
          # ordinarily be bound by the parent Puppet manifest.
        rescue TypeError
          # This is normal because we don't have the variables that would
          # ordinarily be bound by the parent Puppet manifest.
        rescue SyntaxError => error
          errors << error
        end
      end

      $stderr = STDERR
      errors << warnings.string unless warnings.string.empty?
      errors.map! { |e| e.to_s }

      errors
    end
  end
end
