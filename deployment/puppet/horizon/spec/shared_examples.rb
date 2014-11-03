shared_examples_for "a Puppet::Error" do |description|
  it "with message matching #{description.inspect}" do
    expect { subject }.to raise_error(Puppet::Error, description)
  end
end
