require "erb"
puts ERB.new("Hi <%= name %>").result_with_hash({"name" => "x"})
puts ERB.new("<% [1,2].each do |i| %><%= i %><% end %>").result_with_hash({})
