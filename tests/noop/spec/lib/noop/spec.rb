class Noop
  module Spec
    def resource_test_template(binding)
      template = <<-'eof'
  it do
    expect(subject).to contain_<%= resource.type.gsub('::', '__').downcase %>('<%= resource.title %>').with(
<% max_length = resource.to_hash.keys.inject(0) { |ml, key| key = key.to_s; ml = key.size if key.size > ml; ml } -%>
<% resource.each do |parameter, value| -%>
      <%= ":#{parameter}".to_s.ljust(max_length + 1) %> => <%= value.inspect %>,
<% end -%>
    )
  end

      eof
      ERB.new(template, nil, '-').result(binding)
    end

    def catalog_to_spec(context)
      catalog = context.subject
      catalog = catalog.call if catalog.is_a? Proc
      text = ''
      catalog.resources.each do |resource|
        next if %w(Stage Anchor).include? resource.type
        next if resource.type == 'Class' and %w(Settings main).include? resource.title.to_s
        text += resource_test_template(binding)
      end
      text
    end

    def generated_spec_base_dir
      return @generated_spec_base_dir if @generated_spec_base_dir
      @generated_spec_base_dir = File.expand_path File.join(spec_path, '..', '..', 'generated_spec')
    end

    def generated_spec_path(context)
      manifest_name = manifest.gsub '/', '-'
      os = current_os context
      File.join generated_spec_base_dir, "#{manifest_name}-#{os}-generated_spec.rb"
    end

    def save_generated_spec_to_file(context)
      FileUtils.mkdir_p generated_spec_base_dir unless File.directory? generated_spec_base_dir
      text = catalog_to_spec context
      spec_file = generated_spec_path(context)
      debug "Dumping spec to: '#{spec_file}'"
      File.open(spec_file, 'w') do |file|
        file.puts text
      end
    end

  end
  extend Spec
end
