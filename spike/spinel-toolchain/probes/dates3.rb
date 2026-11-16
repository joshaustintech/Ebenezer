require "yaml"
doc = YAML.parse("date: 2026-11-15\ntags: [a, b]\ntitle: Hi\nn: 3\n")
root = doc.root
root.children.each_slice(2) do |k, v|
  if v.is_a?(Psych::Nodes::Scalar)
    puts "#{k.value} => scalar #{v.value.inspect} quoted=#{v.quoted}"
  else
    puts "#{k.value} => #{v.class}"
  end
end
