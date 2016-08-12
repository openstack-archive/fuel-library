require 'spec_helper'

class_object = Puppet::Type.type(:package)

describe class_object do
  before(:each) do
    class_object.packages = {}
    puppet_debug_override
  end

  context 'with "ensure" set to "present"' do
    subject do
      class_object.new(
          :name => 'test',
          :provider => 'apt',
          :ensure => 'present',
      )
    end

    it 'should exits' do
      is_expected.not_to be_nil
    end

    it 'should have name "test"' do
      expect(subject[:name]).to eq 'test'
    end

    context 'with Hiera data "1.0.0"' do
      before(:each) do
        class_object.packages = {'test' => '1.0.0'}
      end

      it 'should have ensure "1.0.0"' do
        expect(subject[:ensure]).to eq '1.0.0'
      end
    end

    context 'with all packages Hiera data "1.0.0"' do
      before(:each) do
        class_object.packages = {'*' => '1.0.0'}
      end

      it 'should have ensure "1.0.0"' do
        expect(subject[:ensure]).to eq '1.0.0'
      end
    end

    context 'with all packages Hiera data "latest"' do
      before(:each) do
        class_object.packages = {'*' => 'latest'}
      end

      it 'should have ensure :latest' do
        expect(subject[:ensure]).to eq :latest
      end
    end

    context 'with all packages Hiera data "1.0.0" and this package set to 2.0.0' do
      before(:each) do
        class_object.packages = {'*' => '1.0.0', 'test' => '2.0.0'}
      end

      it 'should have ensure "1.0.0"' do
        expect(subject[:ensure]).to eq '2.0.0'
      end
    end

    context 'with Hiera data "100"' do
      before(:each) do
        class_object.packages = {'test' => 100}
      end

      it 'should have ensure "100"' do
        expect(subject[:ensure]).to eq '100'
      end
    end

    context 'with Hiera data "absent"' do
      before(:each) do
        class_object.packages = {'test' => 'absent'}
      end

      it 'should have ensure "absent"' do
        expect(subject[:ensure]).to eq :absent
      end
    end

    context 'without Hiera data' do
      before(:each) do
        class_object.packages = {}
      end

      it 'should have ensure "installed"' do
        expect(subject[:ensure]).to eq :present
      end
    end
  end

  context 'with "ensure" unset' do
    subject do
      class_object.new(
          :name => 'test',
          :provider => 'apt',
      )
    end

    it 'should exits' do
      is_expected.not_to be_nil
    end

    it 'should have name "test"' do
      expect(subject[:name]).to eq 'test'
    end

    context 'with Hiera data "1.0.0"' do
      before(:each) do
        class_object.packages = {'test' => '1.0.0'}
      end

      it 'should have ensure "1.0.0"' do
        expect(subject[:ensure]).to eq '1.0.0'
      end
    end

    context 'with all packages Hiera data "1.0.0"' do
      before(:each) do
        class_object.packages = {'*' => '1.0.0'}
      end

      it 'should have ensure "1.0.0"' do
        expect(subject[:ensure]).to eq '1.0.0'
      end
    end

    context 'with all packages Hiera data "latest"' do
      before(:each) do
        class_object.packages = {'*' => 'latest'}
      end

      it 'should have ensure :latest' do
        expect(subject[:ensure]).to eq :latest
      end
    end

    context 'with all packages Hiera data "1.0.0" and this package set to 2.0.0' do
      before(:each) do
        class_object.packages = {'*' => '1.0.0', 'test' => '2.0.0'}
      end

      it 'should have ensure "1.0.0"' do
        expect(subject[:ensure]).to eq '2.0.0'
      end
    end

    context 'with Hiera data "100"' do
      before(:each) do
        class_object.packages = {'test' => 100}
      end

      it 'should have ensure "100"' do
        expect(subject[:ensure]).to eq '100'
      end
    end

    context 'with Hiera data "absent"' do
      before(:each) do
        class_object.packages = {'test' => 'absent'}
      end

      it 'should have ensure "absent"' do
        expect(subject[:ensure]).to eq :absent
      end
    end

    context 'without Hiera data' do
      before(:each) do
        class_object.packages = {}
      end

      it 'should have ensure "present"' do
        expect(subject[:ensure]).to eq :present
      end
    end
  end

end
