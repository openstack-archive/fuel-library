require File.expand_path('../../spec_helper', __FILE__)

describe command('ruby -e "require \'rubygems\'; require \'mysql\';"') do
  it { should return_exit_status 0 }
end
