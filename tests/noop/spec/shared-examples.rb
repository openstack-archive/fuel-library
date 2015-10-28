shared_examples 'compile' do
  it do
    expect(subject).to compile
  end
end

shared_examples 'debug' do
  it 'shows catalog contents' do
    Noop.dump_catalog subject, example
  end
end

shared_examples 'generate' do
  it 'shows catalog contents' do
    Noop.catalog_to_spec subject, example
  end
end

shared_examples 'status' do
  it 'shows status' do
    Noop.status_report example
  end
end

shared_examples 'saved_catalog' do |*resources|
  it 'saves catalog to a file' do
    Noop.save_catalog_to_file subject, resources
  end
  it 'saved catalog matches the current one' do
  end
end

shared_examples 'OS' do
  include_examples 'compile'

  
  include_examples 'status' if ENV['SPEC_SHOW_STATUS']
  include_examples 'debug' if ENV['SPEC_CATALOG_DEBUG']
  include_examples 'generate' if ENV['SPEC_SPEC_GENERATE']
  include_examples 'save_files_list' if ENV['SPEC_SAVE_FILE_RESOURCES']
  include_examples 'save_packages_list'if ENV['SPEC_SAVE_PACKAGE_RESOURCES']
  include_examples 'should_not_install_bin_files_with_puppet' if ENV['SPEC_PUPPET_BINARY_FILES']

  begin
    include_examples 'catalog'
  rescue ArgumentError
    true
  end

  begin
    include_examples 'saved_catalog'
  rescue ArgumentError
    true
  end

  # Noop.coverage_report if ENV['SPEC_COVERAGE']
end

###############################################################################

def test_ubuntu_and_centos(manifest_file, force_manifest = false)

  # check if task is present in the task list
  unless force_manifest or Noop.manifest_present? manifest_file
    Noop.debug "Manifest '#{manifest_file}' is not enabled on the node '#{Noop.hostname}'. Skipping tests."
    return
  end

  # set manifest file
  before(:all) do
    GC.disable
    Noop.manifest = manifest_file
  end

  after(:each) do
    GC.enable
    GC.start
    GC.disable
  end

  if Noop.test_ubuntu?
    context 'on Ubuntu platforms' do
      before(:all) do
        Noop.setup_overrides
      end
      let(:facts) do
        Noop.ubuntu_facts
      end
      include_examples 'OS'
    end
  end

  if Noop.test_centos?
    context 'on CentOS platforms' do
      before(:all) do
        Noop.setup_overrides
      end
      let(:facts) do
        Noop.centos_facts
      end
      include_examples 'OS'
    end
  end

end

