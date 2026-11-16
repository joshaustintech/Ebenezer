require "liquid"
t = Liquid::Template.parse("Hi {{ name | upcase }}! {% for x in items %}[{{ x }}]{% endfor %}")
puts t.render("name" => "spinel", "items" => [1, 2, 3])
