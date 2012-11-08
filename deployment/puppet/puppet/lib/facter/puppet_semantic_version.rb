semantic_version_values = [
  :puppet_major_version,
  :puppet_minor_version,
  :puppet_patch_version
]

semantic_version_values.each_index do |index|
  fact_name = semantic_version_values[index]
  Facter.add(fact_name) do
    setcode do
      Facter.value(:puppetversion).split('.')[index]
    end
  end
end