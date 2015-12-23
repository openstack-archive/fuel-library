require 'spec_helper'
require 'noop/task'

describe Noop::Task do
  subject do
    Noop::Task.new 'my/test_spec.rb'
  end

  let (:repo_root) do
    File.absolute_path File.join File.dirname(__FILE__), '..', '..', '..', '..'
  end

  context 'spec' do
    it 'has file_name_spec' do
      expect(subject.file_name_spec).to be_a Pathname
      expect(subject.file_name_spec.to_s).to eq 'my/test_spec.rb'
    end

    it 'can set file_name_spec' do
      subject.file_name_spec = 'my/test2_spec.rb'
      expect(subject.file_name_spec).to be_a Pathname
      expect(subject.file_name_spec.to_s).to eq 'my/test2_spec.rb'
    end

    it 'will get spec name from the manifest name' do
      subject.file_name_spec = 'my/test3.pp'
      expect(subject.file_name_spec).to be_a Pathname
      expect(subject.file_name_spec.to_s).to eq 'my/test3_spec.rb'
    end

    it 'has file_name_manifest' do
      expect(subject.file_name_manifest).to be_a Pathname
      expect(subject.file_name_manifest.to_s).to eq "my/test.pp"
    end

    it 'has file_path_manifest' do
      expect(subject.file_path_manifest).to be_a Pathname
      expect(subject.file_path_manifest.to_s).to eq "#{repo_root}/deployment/puppet/osnailyfacter/modular/my/test.pp"
    end

    it 'has file_path_spec' do
      expect(subject.file_path_spec).to be_a Pathname
      expect(subject.file_path_spec.to_s).to eq "#{repo_root}/tests/noop/spec/hosts/my/test_spec.rb"
    end
  end

  context 'facts' do
    it 'has file_name_facts' do
      expect(subject.file_name_facts).to be_a Pathname
      expect(subject.file_name_facts.to_s).to eq 'ubuntu.yaml'
    end

    it 'can set file_name_facts' do
      subject.file_name_facts = 'master.yaml'
      expect(subject.file_name_facts).to be_a Pathname
      expect(subject.file_name_facts.to_s).to eq 'master.yaml'
    end

    it 'will add yaml extension to the facts name' do
      subject.file_name_facts = 'centos'
      expect(subject.file_name_facts).to be_a Pathname
      expect(subject.file_name_facts.to_s).to eq 'centos.yaml'
    end

    it 'has file_path_facts' do
      expect(subject.file_path_facts).to be_a Pathname
      expect(subject.file_path_facts.to_s).to eq "#{repo_root}/tests/noop/facts/ubuntu.yaml"
    end

    it 'has file_name_facts_override' do
      expect(subject.file_name_facts_override).to be_a Pathname
      expect(subject.file_name_facts_override.to_s).to eq "my-test.yaml"
    end

    it 'has file_path_facts_override' do
      expect(subject.file_path_facts_override).to be_a Pathname
      expect(subject.file_path_facts_override.to_s).to eq "#{repo_root}/tests/noop/facts/my-test.yaml"
    end
  end

  context 'hiera' do
    it 'has file_name_hiera' do
      expect(subject.file_name_hiera).to be_a Pathname
      expect(subject.file_name_hiera.to_s).to eq 'novanet-primary-controller.yaml'
    end

    it 'has file_base_hiera' do
      expect(subject.file_base_hiera).to be_a Pathname
      expect(subject.file_base_hiera.to_s).to eq 'novanet-primary-controller'
    end

    it 'has element_hiera' do
      expect(subject.element_hiera).to be_a Pathname
      expect(subject.element_hiera.to_s).to eq 'novanet-primary-controller'
    end

    it 'can set file_name_hiera' do
      subject.file_name_hiera = 'compute.yaml'
      expect(subject.file_name_hiera).to be_a Pathname
      expect(subject.file_name_hiera.to_s).to eq 'compute.yaml'
    end

    it 'will add yaml extension to the hiera name' do
      subject.file_name_hiera = 'controller'
      expect(subject.file_name_hiera).to be_a Pathname
      expect(subject.file_name_hiera.to_s).to eq 'controller.yaml'
    end

    it 'has file_path_hiera' do
      expect(subject.file_path_hiera).to be_a Pathname
      expect(subject.file_path_hiera.to_s).to eq "#{repo_root}/tests/noop/hiera/novanet-primary-controller.yaml"
    end

    it 'has file_name_hiera_override' do
      expect(subject.file_name_hiera_override).to be_a Pathname
      expect(subject.file_name_hiera_override.to_s).to eq "my-test.yaml"
    end

    it 'has file_path_hiera_override' do
      expect(subject.file_path_hiera_override).to be_a Pathname
      expect(subject.file_path_hiera_override.to_s).to eq "#{repo_root}/tests/noop/hiera/override/my-test.yaml"
    end

    it 'has element_hiera_override' do
      expect(subject.element_hiera_override).to be_a Pathname
      expect(subject.element_hiera_override.to_s).to eq "override/my-test"
    end

  end

  context 'globals' do
    it 'has file_path_globals' do
      expect(subject.file_path_globals).to be_a Pathname
      expect(subject.file_path_globals.to_s).to eq "#{repo_root}/tests/noop/hiera/globals/novanet-primary-controller.yaml"
    end

    it 'has file_name_globals' do
      expect(subject.file_name_globals).to be_a Pathname
      expect(subject.file_name_globals.to_s).to eq "novanet-primary-controller.yaml"
    end

    it 'has file_base_globals' do
      expect(subject.file_base_globals).to be_a Pathname
      expect(subject.file_base_globals.to_s).to eq "novanet-primary-controller"
    end

    it 'has element_globals' do
      expect(subject.element_globals).to be_a Pathname
      expect(subject.element_globals.to_s).to eq "globals/novanet-primary-controller"
    end
  end

end
