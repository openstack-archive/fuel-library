module Noop::Spec
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

  def catalog_to_spec(subject)
    text = ''
    catalog = subject
    catalog = subject.call if subject.is_a? Proc
    catalog.resources.each do |resource|
      next if %w(Stage Anchor).include? resource.type
      next if resource.type == 'Class' and %w(Settings main).include? resource.title.to_s
      text += resource_test_template(binding)
    end
  end

  def save_generated_spec_to_file(subject, example)
    text = catalog_to_spec subject
    file_name = "#{astute_yaml_base}-#{File.basename current_spec example}_spec.rb"
    spec_file = File.join self.puppet_logs_dir, file_name
    puts "Dumping spec to: '#{file_name}'"
    File.open(spec_file, 'w') do |file|
      file.puts text
    end
  end
end
