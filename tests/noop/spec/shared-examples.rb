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

shared_examples 'OS' do
  it_behaves_like 'compile'

  it_behaves_like 'status' if ENV['SPEC_SHOW_STATUS']
  it_behaves_like 'debug' if ENV['SPEC_CATALOG_DEBUG']
  it_behaves_like 'generate' if ENV['SPEC_SPEC_GENERATE']
  it_behaves_like 'save_files_list' if ENV['SPEC_SAVE_FILE_RESOURCES']
  it_behaves_like 'save_packages_list'if ENV['SPEC_SAVE_PACKAGE_RESOURCES']
  it_behaves_like 'should_not_install_bin_files_with_puppet' if ENV['SPEC_PUPPET_BINARY_FILES']

  begin
    it_behaves_like 'catalog'
  rescue ArgumentError
    true
  end

  Noop.coverage_report if ENV['SPEC_COVERAGE']
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

  # let(:os_name) do
  #   os = facts[:operatingsystem]
  #   os = os.downcase if os
  #   os
  # end

  # let(:catalog) do
  #   catalog = subject
  #   catalog = subject.call if subject.is_a? Proc
  #   catalog
  # end

  if Noop.test_ubuntu?
    context 'on Ubuntu platforms' do
      before(:all) do
        Noop.setup_overrides
      end
      let(:facts) { Noop.ubuntu_facts }
      it_behaves_like 'OS'
    end
  end

  if Noop.test_centos?
    context 'on CentOS platforms' do
      before(:all) do
        Noop.setup_overrides
      end
      let(:facts) { Noop.centos_facts }
      it_behaves_like 'OS'
    end
  end

end

