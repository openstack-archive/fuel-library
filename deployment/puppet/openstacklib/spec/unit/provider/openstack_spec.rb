require 'puppet'
require 'spec_helper'
require 'puppet/provider/openstack'

describe Puppet::Provider::Openstack do
  before(:each) do
    ENV['OS_USERNAME']     = nil
    ENV['OS_PASSWORD']     = nil
    ENV['OS_PROJECT_NAME'] = nil
    ENV['OS_AUTH_URL']     = nil
  end

  let(:type) do
    Puppet::Type.newtype(:test_resource) do
      newparam(:name, :namevar => true)
      newparam(:log_file)
    end
  end

  describe '#request' do
    let(:resource_attrs) do
      {
        :name => 'stubresource',
      }
    end

    let(:provider) do
      Puppet::Provider::Openstack.new(type.new(resource_attrs))
    end

    it 'makes a successful request' do
      provider.class.stubs(:openstack)
                    .with('project', 'list', '--quiet', '--format', 'csv', ['--long'])
                    .returns('"ID","Name","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","test","Test tenant",True
')
      response = Puppet::Provider::Openstack.request('project', 'list', ['--long'])
      expect(response.first[:description]).to eq("Test tenant")
    end

    context 'on connection errors' do
      it 'retries' do
        ENV['OS_USERNAME']     = 'test'
        ENV['OS_PASSWORD']     = 'abc123'
        ENV['OS_PROJECT_NAME'] = 'test'
        ENV['OS_AUTH_URL']     = 'http://127.0.0.1:5000'
        provider.class.stubs(:openstack)
                      .with('project', 'list', '--quiet', '--format', 'csv', ['--long'])
                      .raises(Puppet::ExecutionFailure, 'Unable to establish connection')
                      .then
                      .returns('')
        provider.class.expects(:sleep).with(2).returns(nil)
        Puppet::Provider::Openstack.request('project', 'list', ['--long'])
      end
    end
  end

  describe 'parse_csv' do
    context 'with mixed stderr' do
      text = "ERROR: Testing\n\"field\",\"test\",1,2,3\n"
      csv = Puppet::Provider::Openstack.parse_csv(text)
      it 'should ignore non-CSV text at the beginning of the input' do
        expect(csv).to be_kind_of(Array)
        expect(csv[0]).to match_array(['field', 'test', '1', '2', '3'])
        expect(csv.size).to eq(1)
      end
    end

    context 'with \r\n line endings' do
      text = "ERROR: Testing\r\n\"field\",\"test\",1,2,3\r\n"
      csv = Puppet::Provider::Openstack.parse_csv(text)
      it 'ignore the carriage returns' do
        expect(csv).to be_kind_of(Array)
        expect(csv[0]).to match_array(['field', 'test', '1', '2', '3'])
        expect(csv.size).to eq(1)
      end
    end

    context 'with embedded newlines' do
      text = "ERROR: Testing\n\"field\",\"te\nst\",1,2,3\n"
      csv = Puppet::Provider::Openstack.parse_csv(text)
      it 'should parse correctly' do
        expect(csv).to be_kind_of(Array)
        expect(csv[0]).to match_array(['field', "te\nst", '1', '2', '3'])
        expect(csv.size).to eq(1)
      end
    end
  end
end
