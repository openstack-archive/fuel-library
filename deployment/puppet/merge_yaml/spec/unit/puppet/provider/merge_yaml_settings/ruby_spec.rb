require 'spec_helper'

describe Puppet::Type.type(:merge_yaml_settings).provider(:ruby) do
  before(:each) do
    puppet_debug_override
  end

  let(:path1) do
    '/tmp/test1.yaml'
  end

  let(:path2) do
    '/tmp/test2.yaml'
  end

  let(:path3) do
    '/tmp/test3.yaml'
  end

  let(:resource) do
    Puppet::Type.type(:merge_yaml_settings).new(
        {
            :title => 'test',
            :path => path1,
            :original_data => path2,
            :override_data => path3,
        }
    )
  end

  let(:provider) do
    resource.provider
  end

  subject { provider }

  it do
    is_expected.not_to be_nil
  end

  context 'retrieval' do

    it 'can get the original data from the target file' do
      expect(provider).to receive(:target_yaml_file?).and_return(true)
      expect(provider).to receive(:read_from_file).with(path1).and_return({'a' => '1'})
      expect(provider.original_data).to eq('a' => '1')
    end

    it 'can get the original data from the original file' do
      expect(provider).to receive(:target_yaml_file?).and_return(false)
      expect(provider).to receive(:original_data_file?).and_return(true)
      expect(provider).to receive(:read_from_file).with(path2).and_return({'a' => '2'})
      expect(provider.original_data).to eq('a' => '2')
    end

    it 'can get the original data from the parameter' do
      resource[:original_data] = {'a' => '3'}
      expect(provider).to receive(:target_yaml_file?).and_return(false)
      expect(provider).to receive(:original_data_file?).and_return(false)
      expect(provider.original_data).to eq('a' => '3')
    end

    it 'can get the override data from the override file' do
      expect(provider).to receive(:override_data_file?).and_return(true)
      expect(provider).to receive(:read_from_file).with(path3).and_return({'b' => '1'})
      expect(provider.override_data).to eq('b' => '1')
    end

    it 'can get the override data from the override file' do
      resource[:override_data] = {'b' => '2'}
      expect(provider).to receive(:override_data_file?).and_return(false)
      expect(provider.override_data).to eq('b' => '2')
    end

  end

  context 'merge' do
    it 'can merge the original data with override data' do
      expect(provider).to receive(:original_data).and_return('a' => '1', 'c' => '1')
      expect(provider).to receive(:override_data).and_return('b' => '2', 'c' => '2')
      expect(provider.merged_data).to eq('a' => '1', 'b' => '2', 'c' => '2')
    end

    it 'the merge should not modify the original data' do
      resource[:original_data] = {'a' => '1'}
      expect(provider).to receive(:target_yaml_file?).and_return(false)
      expect(provider).to receive(:original_data_file?).and_return(false)
      expect(provider).to receive(:override_data).and_return('b' => '2')
      expect(provider.merged_data).to eq('a' => '1', 'b' => '2')
      expect(provider.original_data).to eq('a' => '1')
    end

    it 'will merge the array values' do
      resource[:sort_merged_arrays] = true
      expect(provider).to receive(:original_data).and_return('a' => ['1']).at_least(:once)
      expect(provider).to receive(:override_data).and_return('a' => ['2']).at_least(:once)
      expect(provider.merged_data).to eq('a' => %w(1 2))
    end

    it 'will replace array values instead of merging them if :overwrite_arrays' do
      resource[:sort_merged_arrays] = true
      resource[:overwrite_arrays] = true
      expect(provider).to receive(:original_data).and_return('a' => ['1']).at_least(:once)
      expect(provider).to receive(:override_data).and_return('a' => ['2']).at_least(:once)
      expect(provider.merged_data).to eq('a' => %w(2))
    end

  end

  context 'transaction' do
    it 'will detect if the merged data is different from the original data' do
      expect(provider).to receive(:target_yaml_file?).and_return(true)
      expect(provider).to receive(:original_data).and_return('a' => '1').at_least(:once)
      expect(provider).to receive(:merged_data).and_return('a' => '2').at_least(:once)
      expect(provider.exists?).to eq false
    end

    it 'will not do anything if the original_data and the merged_data is same' do
      expect(provider).to receive(:target_yaml_file?).and_return(true)
      expect(provider).to receive(:original_data).and_return('a' => '1').at_least(:once)
      expect(provider).to receive(:merged_data).and_return('a' => '1').at_least(:once)
      expect(provider.exists?).to eq true
    end
  end

end
