require 'puppet'

describe Puppet::Type.type(:nova_secrule) do

  context 'with ip_range based rules' do

    before :each do
      @secrule = Puppet::Type.type(:nova_secrule).new({
        :name => 'test rule',
        :ip_protocol => 'tcp',
        :from_port => '80',
        :to_port => '80',
        :ip_range => '10.0.0.0/8',
        :security_group => 'test',
      })
    end

    it 'should accept only supported protocols' do
      @secrule[:ip_protocol] = 'tcp'
      expect(@secrule[:ip_protocol]).to eq(:tcp)
      expect{
        @secrule[:ip_protocol] = 'http'
      }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should accept valid from and to ports' do
      @secrule[:from_port] = '1'
      expect(@secrule[:from_port]).to eq('1')
      @secrule[:to_port] = '2'
      expect(@secrule[:to_port]).to eq('2')
    end

    it 'should not accept incorrect port values' do
      expect do
        secrule = Puppet::Type.type(:nova_secrule).new({
          :name => 'test rule',
          :ip_protocol => 'tcp',
          :from_port => 'a',
          :to_port => 'b',
          :ip_range => '10.0.0.0/8',
          :security_group => 'test',
        })
      end.to raise_error
      expect do
        secrule = Puppet::Type.type(:nova_secrule).new({
          :name => 'test rule',
          :ip_protocol => 'tcp',
          :from_port => '1',
          :to_port => '100000',
          :ip_range => '10.0.0.0/8',
          :security_group => 'test',
        })
      end.to raise_error
      expect do
        secrule = Puppet::Type.type(:nova_secrule).new({
          :name => 'test rule',
          :ip_protocol => 'tcp',
          :from_port => '80',
          :to_port => '70',
          :ip_range => '10.0.0.0/8',
          :security_group => 'test',
        })
      end.to raise_error
    end

    it 'should accept only correct ip_range' do
      @secrule[:ip_range] = '10.0.0.0/8'
      expect(@secrule[:ip_range]).to eq('10.0.0.0/8')
      expect do
        secrule = Puppet::Type.type(:nova_secrule).new({
          :name => 'test rule',
          :ip_protocol => 'tcp',
          :from_port => '80',
          :to_port => '80',
          :ip_range => '123',
          :security_group => 'test',
        })
      end.to raise_error
      expect do
        secrule = Puppet::Type.type(:nova_secrule).new({
          :name => 'test rule',
          :ip_protocol => 'tcp',
          :from_port => '80',
          :to_port => '80',
          :ip_range => '10.256.0.0/8',
          :security_group => 'test',
        })
      end.to raise_error
      expect do
        secrule = Puppet::Type.type(:nova_secrule).new({
          :name => 'test rule',
          :ip_protocol => 'tcp',
          :from_port => '80',
          :to_port => '80',
          :ip_range => '10.0.0.0/34',
          :security_group => 'test',
        })
      end.to raise_error
      expect do
        secrule = Puppet::Type.type(:nova_secrule).new({
          :name => 'test rule',
          :ip_protocol => 'tcp',
          :from_port => '80',
          :to_port => '80',
          :ip_range => '10.0.0.0',
          :security_group => 'test',
        })
      end.to raise_error
    end

    it 'should accept any security group' do
      @secrule[:security_group] = 'test'
      expect(@secrule[:security_group]).to eq('test')
    end

  end

  context 'with source_group based rules' do
    before(:each) do
      @secrule = Puppet::Type.type(:nova_secrule).new({
        :name => 'test rule',
        :ip_protocol => 'tcp',
        :from_port => '80',
        :to_port => '80',
        :source_group => 'cluster',
        :security_group => 'test',
      })
    end

    it 'should accept any source group' do
      @secrule[:source_group] = 'test'
      expect(@secrule[:source_group]).to eq('test')
    end

    it 'should not accept neither both nor none of source_group and ip_range' do
      expect do
        secrule = Puppet::Type.type(:nova_secrule).new({
          :name => 'test rule',
          :ip_protocol => 'tcp',
          :from_port => '80',
          :to_port => '80',
          :ip_range => '10.0.0.0',
          :source_group => 'cluster',
          :security_group => 'test',
        })
      end.to raise_error
      expect do
        secrule = Puppet::Type.type(:nova_secrule).new({
          :name => 'test rule',
          :ip_protocol => 'tcp',
          :from_port => '80',
          :to_port => '80',
          :security_group => 'test',
        })
      end.to raise_error
    end

  end

end
