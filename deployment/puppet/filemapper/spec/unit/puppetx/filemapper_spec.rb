require 'spec_helper'
require 'puppetx/filemapper'

describe PuppetX::FileMapper do

  before do
    @ramtype  = Puppet::Util::FileType.filetype(:ram)
    @flattype = stub 'Class<FileType<Flat>>'
    @crontype  = stub 'Class<FileType<Crontab>>'

    Puppet::Util::FileType.stubs(:filetype).with(:flat).returns @flattype
    Puppet::Util::FileType.stubs(:filetype).with(:crontab).returns @crontype
  end

  after :each do
    dummytype.defaultprovider = nil
  end

  let(:dummytype) do
    Puppet::Type.newtype(:dummy) do
      ensurable
      newparam(:name, :namevar => true)
      newparam(:dummy_param)
      newproperty(:dummy_property)
    end
  end

  let(:single_file_provider) do
    dummytype.provide(:single) do
      include PuppetX::FileMapper
      def self.target_files; ['/single/file/provider']; end
      def self.parse_file(filename, content)
        [{:name => 'yay', :dummy_param => :bla, :dummy_property => 'baz'}]
      end
      def select_file; '/single/file/provider'; end
      def self.format_file(filename, providers); 'flushback'; end
    end
  end

  let(:multiple_file_provider) do
    dummytype.provide(:multiple, :resource_type => dummytype) do
      include PuppetX::FileMapper
      def self.target_files; ['/multiple/file/provider-one', '/multiple/file/provider-two']; end
      def self.parse_file(filename, content)
        case filename
        when '/multiple/file/provider-one' then [{:name => 'yay', :dummy_param => :bla, :dummy_property => 'baz'}]
        when '/multiple/file/provider-two' then [{:name => 'whee', :dummy_param => :ohai, :dummy_property => 'wat'}]
        end
      end
      def select_file; '/multiple/file/provider-flush'; end
      def self.format_file(filename, providers); 'multiple flush content'; end
    end
  end

  let(:params_yay)  { {:name => 'yay', :dummy_param => :bla, :dummy_property => 'baz'} }
  let(:params_whee) { {:name => 'whee', :dummy_param => :ohai, :dummy_property => 'wat'} }
  let(:params_nope) { {:name => 'dead', :dummy_param => :nofoo, :dummy_property => 'sadprop'} }

  after :each do
    dummytype.provider_hash.clear
  end

  describe 'when included' do
    describe 'after initilizing attributes' do
      subject { dummytype.provide(:foo) { include PuppetX::FileMapper } }

      its(:mapped_files) { should be_empty }
      its(:unlink_empty_files) { should eq(false) }
      its(:filetype) { should eq(:flat) }
      it { should_not be_failed }
    end

    describe 'when generating attr_accessors' do
      subject { multiple_file_provider.new(params_yay) }

      describe 'for properties' do
        it { should respond_to :dummy_property }
        it { should respond_to :dummy_property= }
        it { should respond_to :ensure }
        it { should respond_to :ensure= }
      end

      describe 'for parameters' do
        it { should_not respond_to :dummy_param }
        it { should_not respond_to :dummy_param= }
      end
    end
  end

  describe 'when validating the class' do
    describe "and it doesn't implement self.target_files" do
      subject do
        dummytype.provide(:incomplete) { include PuppetX::FileMapper }
      end

      it { expect { subject.validate_class! }.to raise_error Puppet::DevError, /self.target_files/ }
    end

    describe "and it doesn't implement self.parse_file" do
      subject do
        dummytype.provide(:incomplete) do
          include PuppetX::FileMapper
          def self.target_files; end
        end
      end

      it { expect { subject.validate_class! }.to raise_error Puppet::DevError, /self.parse_file/}
    end

    describe "and it doesn't implement #select_file" do
      subject do
        dummytype.provide(:incomplete) do
          include PuppetX::FileMapper
          def self.target_files; end
          def self.parse_file(filename, content); end
          def self.format_file(filename, resources); 'foo'; end
        end
      end

      it { expect { subject.validate_class! }.to raise_error Puppet::DevError, /#select_file/}
    end

    describe "and it doesn't implement self.format_file" do
      subject do
        dummytype.provide(:incomplete) do
          include PuppetX::FileMapper
          def self.target_files; end
          def self.parse_file(filename, content); end
          def select_file; '/single/file/provider'; end
        end
      end

      it { expect { subject.validate_class! }.to raise_error Puppet::DevError, /self\.format_file/}
    end
  end

  describe 'when reading' do
    describe 'a single file' do

      subject { single_file_provider }

      it 'should generate a filetype for that file' do
        @flattype.expects(:new).with('/single/file/provider').once.returns @ramtype.new('/single/file/provider')
        subject.load_all_providers_from_disk
      end

      it 'should parse each file' do
        stub_file = stub(:read => 'file contents')
        @flattype.stubs(:new).with('/single/file/provider').once.returns stub_file
        subject.expects(:parse_file).with('/single/file/provider', 'file contents').returns []
        subject.load_all_providers_from_disk
      end

      it 'should return the generated array' do
        @flattype.stubs(:new).with('/single/file/provider').once.returns @ramtype.new('/single/file/provider')
        subject.load_all_providers_from_disk.should == [params_yay]
      end
    end

    describe 'multiple files' do
      subject { multiple_file_provider }

      it 'should generate a filetype for each file' do
        @flattype.expects(:new).with('/multiple/file/provider-one').once.returns(stub(:read => 'barbar'))
        @flattype.expects(:new).with('/multiple/file/provider-two').once.returns(stub(:read => 'bazbaz'))
        subject.load_all_providers_from_disk
      end

      describe 'when parsing' do
        before do
          @flattype.stubs(:new).with('/multiple/file/provider-one').once.returns(stub(:read => 'barbar'))
          @flattype.stubs(:new).with('/multiple/file/provider-two').once.returns(stub(:read => 'bazbaz'))
        end

        it 'should parse each file' do
          subject.expects(:parse_file).with('/multiple/file/provider-one', 'barbar').returns []
          subject.expects(:parse_file).with('/multiple/file/provider-two', 'bazbaz').returns []
          subject.load_all_providers_from_disk
        end

        it 'should return the generated array' do
          data = subject.load_all_providers_from_disk
          data.should be_include(params_yay)
          data.should be_include(params_whee)
        end
      end
    end

    describe 'validating input' do
      subject { multiple_file_provider }

      before do
        @flattype.stubs(:new).with('/multiple/file/provider-one').once.returns(stub(:read => 'barbar'))
        @flattype.stubs(:new).with('/multiple/file/provider-two').once.returns(stub(:read => 'bazbaz'))
      end

      it 'should ensure that retrieved values are in the right format' do
        subject.stubs(:parse_file).with('/multiple/file/provider-one', 'barbar').returns Hash.new
        subject.stubs(:parse_file).with('/multiple/file/provider-two', 'bazbaz').returns Hash.new

        expect { subject.load_all_providers_from_disk }.to raise_error Puppet::DevError, /expected.*to return an Array, got a Hash/
      end
    end
  end

  describe 'when generating instances' do
    subject { multiple_file_provider }

    before do
      @flattype.stubs(:new).with('/multiple/file/provider-one').once.returns(stub(:read => 'barbar'))
      @flattype.stubs(:new).with('/multiple/file/provider-two').once.returns(stub(:read => 'bazbaz'))
    end

    it 'should generate a provider instance from hashes' do

      params_yay.merge!({:provider => subject.name})
      params_whee.merge!({:provider => subject.name})

      subject.expects(:new).with(params_yay.merge({:ensure => :present})).returns stub()
      subject.expects(:new).with(params_whee.merge({:ensure => :present})).returns stub()
      subject.instances

    end

    it 'should generate a provider instance for each hash' do
      provs = subject.instances
      provs.should have(2).items
      provs.each { |prov| prov.should be_a_kind_of(Puppet::Provider)}
    end

    [
      {:name => 'yay', :dummy_property => 'baz'},
      {:name => 'whee', :dummy_property => 'wat'},
    ].each do |values|
      it "should match hash values to provider properties for #{values[:name]}" do
        provs = subject.instances
        prov = provs.find {|prov| prov.name == values[:name]}
        values.each_pair { |property, value| prov.send(property).should == value }
      end
    end
  end

  describe 'when prefetching' do
    subject { multiple_file_provider }

    let(:provider_yay) { subject.new(params_yay.merge({:provider => subject.name})) }
    let(:provider_whee) { subject.new(params_whee.merge({:provider => subject.name})) }

    before do
      subject.stubs(:instances).returns [provider_yay, provider_whee]
    end

    let(:resources) do
      [params_yay, params_whee, params_nope].inject({}) do |h, params|
        h[params[:name]] = dummytype.new(params)
        h
      end
    end

    it "should update resources with existing providers" do
      resources['yay'].expects(:provider=).with(provider_yay)
      resources['whee'].expects(:provider=).with(provider_whee)

      subject.prefetch(resources)
    end

    it "should not update resources that don't have providers" do
      resources['dead'].expects(:provider=).never
      subject.prefetch(resources)
    end
  end

  describe 'on resource state change' do
    subject { multiple_file_provider }

    before do
      dummytype.defaultprovider = subject
      subject.any_instance.stubs(:resource_type).returns dummytype
    end

    describe 'from absent to present' do
      let(:resource) { dummytype.new(:name => 'boom', :dummy_property => 'bang') }
      it 'should mark the related file as dirty' do
        subject.mapped_files['/multiple/file/provider-flush'][:dirty].should be_false
        resource.property(:ensure).sync
        subject.mapped_files['/multiple/file/provider-flush'][:dirty].should be_true
      end
    end

    describe 'from present to absent' do
      it 'should mark the related file as dirty' do
        resource = dummytype.new(:name => 'boom', :dummy_property => 'bang', :ensure => :absent)
        subject.mapped_files['/multiple/file/provider-flush'][:dirty].should be_false
        resource.property(:ensure).sync
        subject.mapped_files['/multiple/file/provider-flush'][:dirty].should be_true
      end
    end

    describe 'on a property' do
      let(:resource) { resource = dummytype.new(params_yay) }

      before do
        prov = subject.new(params_yay.merge({:ensure => :present}))
        subject.stubs(:instances).returns [prov]
        subject.prefetch({params_yay[:name] => resource})
      end

      it 'should mark the related file as dirty' do
        subject.mapped_files['/multiple/file/provider-flush'][:dirty].should be_false
        resource.property(:dummy_property).value = 'new value'
        resource.property(:dummy_property).sync
        subject.mapped_files['/multiple/file/provider-flush'][:dirty].should be_true
      end
    end

    describe 'on a parameter' do
      let(:resource) { resource = dummytype.new(params_yay) }

      before do
        prov = subject.new(params_yay.merge({:ensure => :present}))
        subject.stubs(:instances).returns [prov]
        subject.prefetch({params_yay[:name] => resource})
      end

      it 'should not mark the related file as dirty' do
        subject.mapped_files['/multiple/file/provider-flush'][:dirty].should be_false
        resource.parameter(:dummy_param).value = 'new value'
        resource.flush
        subject.mapped_files['/multiple/file/provider-flush'][:dirty].should be_false
      end
    end
  end

  describe 'when determining whether to flush' do
    subject { multiple_file_provider }

    before do
      dummytype.defaultprovider = subject
      subject.any_instance.stubs(:resource_type).returns dummytype
    end

    let(:resource) { resource = dummytype.new(params_yay) }

    it 'should refuse to flush if the provider is in a failed state' do
      subject.dirty_file!('/multiple/file/provider-flush')
      subject.failed!
      subject.expects(:collect_resources_for_provider).never
      resource.flush
    end

    it 'should use the provider instance method `select_file` to locate the destination file' do
      resource.provider.expects(:select_file).returns '/multiple/file/provider-flush'
      resource.property(:dummy_property).value = 'zoom'
      resource.property(:dummy_property).sync
    end

    it 'should trigger the class dirty_file! method' do
      subject.expects(:dirty_file!).with('/multiple/file/provider-flush')
      resource.property(:dummy_property).value = 'zoom'
      resource.property(:dummy_property).sync
    end
  end

  describe 'when flushing' do

    subject { multiple_file_provider }

    let(:newtype) { @ramtype.new('/multiple/file/provider-flush') }
    let(:resource) { resource = dummytype.new(params_yay) }

    before { newtype.stubs(:backup) }

    it 'should forward provider#flush to the class' do
      subject.expects(:flush_file).with('/multiple/file/provider-flush')
      resource.flush
    end

    it 'should generate filetypes for new files' do
      subject.dirty_file!('/multiple/file/provider-flush')
      @flattype.expects(:new).with('/multiple/file/provider-flush').returns newtype
      resource.flush
    end

    it 'should use existing filetypes for existing files' do
      stub_filetype = stub()
      stub_filetype.expects(:backup)
      stub_filetype.expects(:write)
      subject.dirty_file!('/multiple/file/provider-flush')
      subject.mapped_files['/multiple/file/provider-flush'][:filetype] = stub_filetype
      resource.flush
    end

    it 'should trigger a flush on dirty files' do
      subject.dirty_file!('/multiple/file/provider-flush')
      subject.expects(:perform_write).with('/multiple/file/provider-flush', 'multiple flush content')
      resource.flush
    end

    it 'should not flush clean files' do
      subject.expects(:perform_write).never
      resource.flush
    end
  end

  describe 'validating the file contents to flush' do
    subject { multiple_file_provider }

    before do
      subject.stubs(:format_file).returns ['definitely', 'not', 'of', 'class', 'String']
      subject.dirty_file!('/multiple/file/provider-flush')
    end

    it 'should raise an error if given an invalid value for file contents' do
      subject.expects(:perform_write).with('/multiple/file/provider-flush', %w{invalid data}).never
      expect { subject.flush_file('/multiple/file/provider-flush') }.to raise_error Puppet::DevError, /expected .* to return a String, got a Array/
    end
  end

  describe 'when unlinking empty files' do

    subject { multiple_file_provider }

    let(:newtype) { @ramtype.new('/multiple/file/provider-flush') }

    before do
      subject.unlink_empty_files = true
      newtype.stubs(:backup)
      File.stubs(:unlink)
    end

    describe 'with empty file contents' do
      before do
        subject.dirty_file!('/multiple/file/provider-flush')
        @flattype.stubs(:new).with('/multiple/file/provider-flush').returns newtype
        File.stubs(:exist?).with('/multiple/file/provider-flush').returns true

        subject.stubs(:format_file).returns ''
      end

      it 'should back up the file' do
        newtype.expects(:backup)
        subject.flush_file('/multiple/file/provider-flush')
      end

      it 'should remove the file' do
        File.expects(:unlink).with('/multiple/file/provider-flush')
        subject.flush_file('/multiple/file/provider-flush')
      end

      it 'should not write to the file' do
        subject.expects(:perform_write).with('/multiple/file/provider-flush', '').never
        subject.flush_file('/multiple/file/provider-flush')
      end
    end

    describe 'with empty file contents and no destination file' do
      before do
        subject.dirty_file!('/multiple/file/provider-flush')
        @flattype.stubs(:new).with('/multiple/file/provider-flush').returns newtype
        File.stubs(:exist?).with('/multiple/file/provider-flush').returns false

        subject.stubs(:format_file).returns ''
      end

      it 'should not try to remove the file' do
        File.expects(:exist?).with('/multiple/file/provider-flush').returns false
        File.expects(:unlink).never
        subject.flush_file('/multiple/file/provider-flush')
      end

      it 'should not try to back up the file' do
        newtype.expects(:backup).never
        subject.flush_file('/multiple/file/provider-flush')
      end
    end

    describe 'with a non-empty file' do
      before do
        subject.dirty_file!('/multiple/file/provider-flush')
        @flattype.stubs(:new).with('/multiple/file/provider-flush').returns newtype
        File.stubs(:exist?).with('/multiple/file/provider-flush').returns true

        subject.stubs(:format_file).returns 'not empty'
      end

      it 'should not remove the file' do
        File.expects(:unlink).never
        subject.flush_file('/multiple/file/provider-flush')
      end
    end
  end

  describe 'when using an alternate filetype' do

    subject { multiple_file_provider }

    before do
      subject.filetype = :crontab
    end

    it 'should assign that filetype to loaded files' do
      @crontype.expects(:new).with('/multiple/file/provider-one').once.returns(stub(:read => 'barbar'))
      @crontype.expects(:new).with('/multiple/file/provider-two').once.returns(stub(:read => 'bazbaz'))

      subject.load_all_providers_from_disk
    end

    describe 'that does not implement backup' do
      let(:resource) { resource = dummytype.new(params_yay) }
      let(:stub_filetype) { stub() }

      before :each do
        subject.mapped_files['/multiple/file/provider-flush'][:filetype] = stub_filetype
        subject.dirty_file!('/multiple/file/provider-flush')

        stub_filetype.expects(:respond_to?).with(:backup).returns(false)
        stub_filetype.expects(:backup).never
      end

      it 'should not call backup when writing files' do
        stub_filetype.stubs(:write)

        resource.flush
      end

      it 'should not call backup when unlinking files' do
        subject.unlink_empty_files = true
        subject.stubs(:format_file).returns ''
        File.stubs(:exist?).with('/multiple/file/provider-flush').returns true
        File.stubs(:unlink)

        resource.flush
      end
    end
  end

  describe 'flush hooks' do

    subject { multiple_file_provider }

    before :each do
      subject.dirty_file!('/multiple/file/provider-flush')
    end

    let(:newtype) { @ramtype.new('/multiple/file/provider-flush') }

    it 'should be called in order' do
      seq = sequence('flush')
      subject.expects(:respond_to?).with(:pre_flush_hook).returns true
      subject.expects(:respond_to?).with(:post_flush_hook).returns true
      subject.expects(:pre_flush_hook).with('/multiple/file/provider-flush').in_sequence(seq)
      subject.expects(:perform_write).with('/multiple/file/provider-flush', 'multiple flush content').in_sequence(seq)
      subject.expects(:post_flush_hook).with('/multiple/file/provider-flush').in_sequence(seq)

      subject.flush_file '/multiple/file/provider-flush'
    end

    it 'should call post_flush_hook even if an exception is raised' do
      subject.stubs(:respond_to?).with(:pre_flush_hook).returns false
      subject.stubs(:respond_to?).with(:post_flush_hook).returns true

      subject.expects(:perform_write).with('/multiple/file/provider-flush', 'multiple flush content').raises RuntimeError
      subject.expects(:post_flush_hook)

      expect { subject.flush_file '/multiple/file/provider-flush' }.to raise_error RuntimeError
    end
  end

  describe 'when formatting resources for flushing' do
    let(:provider_class) { multiple_file_provider }

    let(:new_resource) { dummytype.new(params_yay) }

    let(:current_provider) { provider_class.new(params_whee) }
    let(:current_resource) { dummytype.new(params_whee) }

    let(:remove_provider) { provider_class.new(params_nope) }
    let(:remove_resource) { dummytype.new(params_nope.merge({:ensure => :absent})) }

    let(:unmanaged_provider) { provider_class.new(:name => 'unmanaged_resource', :dummy_param => 'zoom', :dummy_property => 'squid', :ensure => :present) }

    let(:provider_stubs) { [current_provider, remove_provider, unmanaged_provider] }
    let(:resource_stubs) { [new_resource, current_resource, remove_resource] }

    before do
      dummytype.defaultprovider = provider_class
      provider_class.any_instance.stubs(:resource_type).returns dummytype

      provider_class.stubs(:instances).returns provider_stubs
      provider_class.prefetch(resource_stubs.inject({}) { |h, r| h[r.name] = r; h})

      # Pretend that we're the resource harness and apply the ensure param
      resource_stubs.each { |r| r.property(:ensure).sync }
    end

    it 'should collect all resources for a given file' do
      provider_class.expects(:collect_providers_for_file).with('/multiple/file/provider-flush').returns []
      provider_class.stubs(:perform_write)
      provider_class.flush_file('/multiple/file/provider-flush')
    end

    describe 'and selecting' do
      subject { multiple_file_provider.collect_providers_for_file('/multiple/file/provider-flush').map(&:name) }

      describe 'present resources' do
        it { should be_include 'yay' }
        it { should be_include 'whee' }
        it { should be_include 'unmanaged_resource' }
      end

      describe 'absent resources' do
        it { should_not be_include 'nope' }
      end
    end
  end
end
