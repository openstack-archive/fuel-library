require 'puppet'
require 'puppet/type/ssl_pkey'
describe Puppet::Type.type(:ssl_pkey) do
  subject { Puppet::Type.type(:ssl_pkey).new(:path => '/tmp/foo.key') }

  it 'should not accept a non absolute path' do
    expect {
      Puppet::Type.type(:ssl_pkey).new(:path => 'foo')
    }.to raise_error(Puppet::Error, /Path must be absolute: foo/)
  end

  it 'should accept ensure' do
    subject[:ensure] = :present
    subject[:ensure].should == :present
  end

  it 'should accept a valid size' do
    subject[:size] = 1024
    subject[:size].should == 1024
  end

  it 'should not accept an invalid size' do
    expect {
      subject[:size] = :foo
    }.to raise_error(Puppet::Error, /Invalid value :foo/)
  end

  it 'should accept a valid authentication' do
    subject[:authentication] = :rsa
    subject[:authentication].should == :rsa
    subject[:authentication] = :dsa
    subject[:authentication].should == :dsa
  end

  it 'should not accept an invalid authentication' do
    expect {
      subject[:authentication] = :foo
    }.to raise_error(Puppet::Error, /Invalid value :foo/)
  end

  it 'should accept a password' do
    subject[:password] = 'foox2$bar'
    subject[:password].should == 'foox2$bar'
  end
end
