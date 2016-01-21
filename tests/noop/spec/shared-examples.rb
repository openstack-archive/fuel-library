shared_examples 'compile' do
  it do
    expect(subject).to compile
  end
end

shared_examples 'show_catalog' do
  it 'shows catalog contents' do
    puts Noop.dump_catalog self
  end
end

shared_examples 'generate' do
  it 'generate a spec stub' do
    Noop.save_generated_spec_to_file self
  end
end

shared_examples 'status' do
  it 'shows status' do
    puts Noop.status_report self
  end
end

shared_examples 'saved_catalog' do |*resources|
  it 'should save the current task catalog to the file', :if => (ENV['SPEC_CATALOG_CHECK'] == 'save') do
    Noop.save_catalog_to_file self, resources.flatten
  end
  it 'should check the current task catalog against the saved one', :if => (ENV['SPEC_CATALOG_CHECK'] == 'check')  do
    saved_catalog = Noop.preprocess_catalog_data Noop.read_catalog_from_file self
    current_catalog = Noop.preprocess_catalog_data Noop.dump_catalog self, resources.flatten
    expect(current_catalog).to eq(saved_catalog)
  end
end

shared_examples 'should_not_install_bin_files_with_puppet' do
  it 'should chack that binary files are not installed by this task' do
    Noop.check_for_binary_files_installation self
  end
end

shared_examples 'save_files_list' do
  it 'should save the list of File resources to the file' do
    Noop.save_file_resources_list_to_file self
  end
end

shared_examples 'OS' do
  include FuelRelationshipGraphMatchers

  let (:catalog) do
     catalog = subject
     catalog = catalog.call if catalog.is_a? Proc
   end

  let (:ral) do
     ral = catalog.to_ral
     ral.finalize
     ral
  end

  let (:graph) do
    graph = Puppet::Graph::RelationshipGraph.new(Puppet::Graph::TitleHashPrioritizer.new)
    graph.populate_from(ral)
  end

  include_examples 'compile'

  include_examples 'status' if ENV['SPEC_SHOW_STATUS']
  include_examples 'show_catalog' if ENV['SPEC_CATALOG_SHOW']
  include_examples 'generate' if ENV['SPEC_SPEC_GENERATE']

  include_examples 'save_files_list' if ENV['SPEC_SAVE_FILE_RESOURCES']
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

end

###############################################################################

def test_ubuntu_and_centos(manifest_file, force_manifest = false)
  run_test(manifest_file, :force_manifest => force_manifest)
end

def test_ubuntu(manifest_file, force_manifest = false)
  run_test(manifest_file, :force_manifest => force_manifest, :run_ubuntu => true, :run_centos => false)
end

def test_centos(manifest_file, force_manifest = false)
  run_test(manifest_file, :force_manifest => force_manifest, :run_ubuntu => false, :run_centos => true)
end

def run_test(manifest_file, options)

  default_options = {
      :force_manifest => false,
      :run_ubuntu => true,
      :run_centos => true,
  }

  options = default_options.merge options

  # check if task is present in the task list
  unless options[:force_manifest] or Noop.manifest_present? manifest_file
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

  if Noop.test_ubuntu? and options[:run_ubuntu]
    context 'on Ubuntu platforms' do
      let(:os) do
        'ubuntu'
      end
      before(:all) do
        Noop.setup_overrides
      end
      let(:facts) do
        Noop.ubuntu_facts
      end
      include_examples 'OS'
      yield self if block_given?
    end
  end

  if Noop.test_centos? and options[:run_centos]
    context 'on CentOS platforms' do
      let(:os) do
        'centos'
      end
      before(:all) do
        Noop.setup_overrides
      end
      let(:facts) do
        Noop.centos_facts
      end
      include_examples 'OS'
      yield self if block_given?
    end
  end

end
