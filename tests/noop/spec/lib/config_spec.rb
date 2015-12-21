require 'spec_helper'
require 'noop/config'
require 'ostruct'

describe Noop::Config do
  let (:repo_root) do
    File.absolute_path File.join File.dirname(__FILE__), '..', '..', '..', '..'
  end

  context 'base' do
    it 'dir_path_config' do
      expect(subject.dir_path_config).to be_a Pathname
      expect(subject.dir_path_config.to_s).to eq "#{repo_root}/tests/noop/lib/noop/config"
    end

    it 'dir_path_task_root' do
      expect(subject.dir_path_task_root).to be_a Pathname
      expect(subject.dir_path_task_root.to_s).to eq "#{repo_root}/tests/noop"
    end

    it 'dir_path_repo_root' do
      expect(subject.dir_path_repo_root).to be_a Pathname
      expect(subject.dir_path_repo_root.to_s).to eq "#{repo_root}"
    end

    it 'dir_path_task_spec' do
      expect(subject.dir_path_task_spec).to be_a Pathname
      expect(subject.dir_path_task_spec.to_s).to eq "#{repo_root}/tests/noop/spec/hosts"
    end

    it 'dir_path_modules_local' do
      expect(subject.dir_path_modules_local).to be_a Pathname
      expect(subject.dir_path_modules_local.to_s).to eq "#{repo_root}/deployment/puppet"
    end

    it 'dir_path_tasks_local' do
      expect(subject.dir_path_tasks_local).to be_a Pathname
      expect(subject.dir_path_tasks_local.to_s).to eq "#{repo_root}/deployment/puppet/osnailyfacter/modular"
    end

    it 'dir_path_modules_node' do
      expect(subject.dir_path_modules_node).to be_a Pathname
      expect(subject.dir_path_modules_node.to_s).to eq "/etc/puppet/modules"
    end

    it 'dir_path_tasks_node' do
      expect(subject.dir_path_tasks_node).to be_a Pathname
      expect(subject.dir_path_tasks_node.to_s).to eq "/etc/puppet/modules/osnailyfacter/modular"
    end

    it 'dir_path_deployment' do
      expect(subject.dir_path_deployment).to be_a Pathname
      expect(subject.dir_path_deployment.to_s).to eq "#{repo_root}/deployment"
    end
  end

  context 'hiera' do
    it 'dir_name_hiera' do
      expect(subject.dir_name_hiera).to be_a Pathname
      expect(subject.dir_name_hiera.to_s).to eq "astute.yaml"
    end

    it 'dir_path_hiera' do
      expect(subject.dir_path_hiera).to be_a Pathname
      expect(subject.dir_path_hiera.to_s).to eq "#{repo_root}/tests/noop/astute.yaml"
    end

    it 'file_name_hiera' do
      expect(subject.file_name_hiera).to be_a Pathname
      expect(subject.file_name_hiera.to_s).to eq "novanet-primary-controller.yaml"
    end

    it 'file_base_hiera' do
      expect(subject.file_base_hiera).to be_a Pathname
      expect(subject.file_base_hiera.to_s).to eq "novanet-primary-controller"
    end

    it 'file_path_hiera' do
      expect(subject.file_path_hiera).to be_a Pathname
      expect(subject.file_path_hiera.to_s).to eq "#{repo_root}/tests/noop/astute.yaml/novanet-primary-controller.yaml"
    end

    it 'element_hiera' do
      expect(subject.element_hiera).to be_a Pathname
      expect(subject.element_hiera.to_s).to eq "novanet-primary-controller"
    end
  end

  context 'globals' do
    it 'dir_name_globals' do
      expect(subject.dir_name_globals).to be_a Pathname
      expect(subject.dir_name_globals.to_s).to eq "globals"
    end

    it 'dir_path_globals' do
      expect(subject.dir_path_globals).to be_a Pathname
      expect(subject.dir_path_globals.to_s).to eq "#{repo_root}/tests/noop/globals"
    end

    it 'file_path_globals' do
      expect(subject.file_path_globals).to be_a Pathname
      expect(subject.file_path_globals.to_s).to eq "#{repo_root}/tests/noop/globals/novanet-primary-controller.yaml"
    end

    it 'file_name_globals' do
      expect(subject.file_name_globals).to be_a Pathname
      expect(subject.file_name_globals.to_s).to eq "novanet-primary-controller.yaml"
    end

    it 'file_base_globals' do
      expect(subject.file_base_globals).to be_a Pathname
      expect(subject.file_base_globals.to_s).to eq "novanet-primary-controller"
    end

    it 'element_globals' do
      expect(subject.element_globals).to be_a Pathname
      expect(subject.element_globals.to_s).to eq "globals/novanet-primary-controller"
    end
  end

  context 'override/facts' do
    before(:each) do
      allow(subject).to receive(:manifest).and_return "test/manifest.pp"
    end

    it 'file_name_facts_override' do
      expect(subject.file_name_facts_override).to be_a Pathname
      expect(subject.file_name_facts_override.to_s).to eq "test-manifest.yaml"
    end

    it 'dir_name_facts_override' do
      expect(subject.dir_name_facts_override).to be_a Pathname
      expect(subject.dir_name_facts_override.to_s).to eq "facts"
    end

    it 'dir_path_facts_override' do
      expect(subject.dir_path_facts_override).to be_a Pathname
      expect(subject.dir_path_facts_override.to_s).to eq "#{repo_root}/tests/noop/facts"
    end

    it 'file_path_facts_override' do
      expect(subject.file_path_facts_override).to be_a Pathname
      expect(subject.file_path_facts_override.to_s).to eq "#{repo_root}/tests/noop/facts/test-manifest.yaml"
    end
  end

  context 'override/hiera' do
    before(:each) do
      allow(subject).to receive(:manifest).and_return "test/manifest.pp"
    end

    it 'file_name_hiera_override' do
      expect(subject.file_name_hiera_override).to be_a Pathname
      expect(subject.file_name_hiera_override.to_s).to eq "test-manifest.yaml"
    end

    it 'dir_name_hiera_override' do
      expect(subject.dir_name_hiera_override).to be_a Pathname
      expect(subject.dir_name_hiera_override.to_s).to eq "override"
    end

    it 'dir_path_hiera_override' do
      expect(subject.dir_path_hiera_override).to be_a Pathname
      expect(subject.dir_path_hiera_override.to_s).to eq "#{repo_root}/tests/noop/astute.yaml/override"
    end

    it 'file_path_hiera_override' do
      expect(subject.file_path_hiera_override).to be_a Pathname
      expect(subject.file_path_hiera_override.to_s).to eq "#{repo_root}/tests/noop/astute.yaml/override/test-manifest.yaml"
    end

    it 'element_hiera_override' do
      expect(subject.element_hiera_override).to be_a Pathname
      expect(subject.element_hiera_override.to_s).to eq "override/test-manifest"
    end
  end

  context 'misc' do
    before(:each) do
      allow(subject).to receive(:manifest).and_return "test/manifest.pp"
    end

    it 'file_name_task_extension' do
      expect(subject.file_name_task_extension).to be_a Pathname
      expect(subject.file_name_task_extension.to_s).to eq "test-manifest.yaml"
    end

    it 'dir_path_workspace' do
      expect(subject.dir_path_workspace).to be_a Pathname
      expect(subject.dir_path_workspace.to_s).to eq "/tmp/noop"
    end
  end

  context 'options' do
    it 'options structure' do
      expect(subject.options).to be_a OpenStruct
    end
  end
end
