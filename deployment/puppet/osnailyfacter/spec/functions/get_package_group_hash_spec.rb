require 'spec_helper'

describe 'get_package_group_hash' do

    let(:input) do
        {"^nova.*$"=>"latest","^mc.*$"=>"latest"}
    end

    let(:non_ascii_input) do
       {"^nova.*$"=>"latest","^mc.*$"=>"latest", "\u2555" => "latest"}
    end

    let(:output) do
        {"nova-common"=>"latest", "nova-compute"=>"latest", "nova-compute-qemu"=>"latest", "mc"=>"latest", "mc-data"=>"latest", "mcollective"=>"latest", "mcollective-common"=>"latest"}
    end

    it 'should return packages with updated versions' do

        scope.stubs(:lookupvar).with('pkglist').returns("nova-common\nnova-compute\nnova-compute-qemu\nmc\nmc-data\nmcollective\nmcollective-common")
        is_expected.to run.with_params(input).and_return(output)
    end

    it 'should skip regex with non-ASCII chars' do
        scope.stubs(:lookupvar).with('pkglist').returns("nova-common\nnova-compute\nnova-compute-qemu\nmc\nmc-data\nmcollective\nmcollective-common")
        is_expected.to run.with_params(non_ascii_input).and_return(output)
    end

end
