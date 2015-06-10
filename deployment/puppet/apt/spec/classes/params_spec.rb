require 'spec_helper'
describe 'apt::params', :type => :class do
  let(:facts) { { :lsbdistid => 'Debian', :osfamily => 'Debian', :lsbdistcodename => 'wheezy', :puppetversion   => '3.5.0', } }
  let (:title) { 'my_package' }

  it { is_expected.to contain_apt__params }

  # There are 4 resources in this class currently
  # there should not be any more resources because it is a params class
  # The resources are class[apt::params], class[main], class[settings], stage[main]
  it "Should not contain any resources" do
    expect(subject.call.resources.size).to eq(4)
  end

  describe "With lsb-release not installed" do
    let(:facts) { { :osfamily => 'Debian', :puppetversion   => '3.5.0', } }
    let (:title) { 'my_package' }

    it do
      expect {
        subject.call
      }.to raise_error(Puppet::Error, /Unable to determine lsbdistid, is lsb-release installed/)
    end
  end

  describe "With old puppet version" do
    let(:facts) { { :lsbdistid => 'Debian', :osfamily => 'Debian', :lsbdistcodename => 'wheezy', :lsbdistrelease => 'foo', :lsbdistdescription => 'bar', :lsbminordistrelease => 'baz', :lsbmajdistrelease => 'foobar', :puppetversion   => '3.4.0', } }
    let(:title) { 'my_package' }
    it { is_expected.to contain_apt__params }

    # There are 4 resources in this class currently
    # there should not be any more resources because it is a params class
    # The resources are class[apt::params], class[main], class[settings], stage[main]
    it "Should not contain any resources" do
      expect(subject.call.resources.size).to eq(4)
    end
  end

end
