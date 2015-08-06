#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:file).attrclass(:mode) do
  include PuppetSpec::Files

  let(:path) { tmpfile('mode_spec') }
  let(:resource) { Puppet::Type.type(:file).new :path => path, :mode => 0644 }
  let(:mode) { resource.property(:mode) }

  describe "#validate" do
    it "should accept values specified as integers" do
      expect { mode.value = 0755 }.not_to raise_error
    end

    it "should accept values specified as octal numbers in strings" do
      expect { mode.value = '0755' }.not_to raise_error
    end

    it "should accept valid symbolic strings" do
      expect { mode.value = 'g+w,u-x' }.not_to raise_error
    end

    it "should not accept strings other than octal numbers" do
      expect do
        mode.value = 'readable please!'
      end.to raise_error(Puppet::Error, /The file mode specification is invalid/)
    end
  end

  describe "#munge" do
    # This is sort of a redundant test, but its spec is important.
    it "should return the value as a string" do
      mode.munge('0644').should be_a(String)
    end

    it "should accept strings as arguments" do
      mode.munge('0644').should == '644'
    end

    it "should accept symbolic strings as arguments and return them intact" do
      mode.munge('u=rw,go=r').should == 'u=rw,go=r'
    end

    it "should accept integers are arguments" do
      mode.munge(0644).should == '644'
    end
  end

  describe "#dirmask" do
    before :each do
      Dir.mkdir(path)
    end

    it "should add execute bits corresponding to read bits for directories" do
      mode.dirmask('0644').should == '755'
    end

    it "should not add an execute bit when there is no read bit" do
      mode.dirmask('0600').should == '700'
    end

    it "should not add execute bits for files that aren't directories" do
      resource[:path] = tmpfile('other_file')
      mode.dirmask('0644').should == '0644'
    end
  end

  describe "#insync?" do
    it "should return true if the mode is correct" do
      FileUtils.touch(path)

      mode.must be_insync('644')
    end

    it "should return false if the mode is incorrect" do
      FileUtils.touch(path)

      mode.must_not be_insync('755')
    end

    it "should return true if the file is a link and we are managing links", :if => Puppet.features.manages_symlinks? do
      Puppet::FileSystem::File.new('anything').symlink(path)

      mode.must be_insync('644')
    end

    describe "with a symbolic mode" do
      let(:resource_sym) { Puppet::Type.type(:file).new :path => path, :mode => 'u+w,g-w' }
      let(:mode_sym) { resource_sym.property(:mode) }

      it "should return true if the mode matches, regardless of other bits" do
        FileUtils.touch(path)

        mode_sym.must be_insync('644')
      end

      it "should return false if the mode requires 0's where there are 1's" do
        FileUtils.touch(path)

        mode_sym.must_not be_insync('624')
      end

      it "should return false if the mode requires 1's where there are 0's" do
        FileUtils.touch(path)

        mode_sym.must_not be_insync('044')
      end
    end
  end

  describe "#retrieve" do
    it "should return absent if the resource doesn't exist" do
      resource[:path] = File.expand_path("/does/not/exist")
      mode.retrieve.should == :absent
    end

    it "should retrieve the directory mode from the provider" do
      Dir.mkdir(path)

      mode.expects(:dirmask).with('644').returns '755'
      resource.provider.expects(:mode).returns '755'

      mode.retrieve.should == '755'
    end

    it "should retrieve the file mode from the provider" do
      FileUtils.touch(path)

      mode.expects(:dirmask).with('644').returns '644'
      resource.provider.expects(:mode).returns '644'

      mode.retrieve.should == '644'
    end
  end

  describe '#should_to_s' do
    describe 'with a 3-digit mode' do
      it 'returns a 4-digit mode with a leading zero' do
        mode.should_to_s('755').should == '0755'
      end
    end

    describe 'with a 4-digit mode' do
      it 'returns the 4-digit mode when the first digit is a zero' do
        mode.should_to_s('0755').should == '0755'
      end

      it 'returns the 4-digit mode when the first digit is not a zero' do
        mode.should_to_s('1755').should == '1755'
      end
    end
  end

  describe '#is_to_s' do
    describe 'with a 3-digit mode' do
      it 'returns a 4-digit mode with a leading zero' do
        mode.is_to_s('755').should == '0755'
      end
    end

    describe 'with a 4-digit mode' do
      it 'returns the 4-digit mode when the first digit is a zero' do
        mode.is_to_s('0755').should == '0755'
      end

      it 'returns the 4-digit mode when the first digit is not a zero' do
        mode.is_to_s('1755').should == '1755'
      end
    end

    describe 'when passed :absent' do
      it 'returns :absent' do
        mode.is_to_s(:absent).should == :absent
      end
    end
  end

  describe "#sync with a symbolic mode" do
    let(:resource_sym) { Puppet::Type.type(:file).new :path => path, :mode => 'u+w,g-w' }
    let(:mode_sym) { resource_sym.property(:mode) }

    before { FileUtils.touch(path) }

    it "changes only the requested bits" do
      # lower nibble must be set to 4 for the sake of passing on Windows
      FileUtils.chmod 0464, path
      mode_sym.sync
      file = Puppet::FileSystem::File.new(path)
      (file.stat.mode & 0777).to_s(8).should == "644"
    end
  end
end
