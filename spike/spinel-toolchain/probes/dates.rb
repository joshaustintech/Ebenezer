require "yaml"
docs = ["date: 2026-11-15", "date: \"2026-11-15\"", "time: 2026-11-15 10:30:00 +00:00", "n: 1.5\nb: yes\nlist: [a, b]\nanchor: &x {k: v}\nref: *x"]
docs.each do |d|
  begin
    p YAML.safe_load(d)
  rescue => e
    puts "safe_load raised #{e.class}: #{e.message}"
  end
  begin
    p YAML.load(d)
  rescue => e
    puts "load raised #{e.class}: #{e.message}"
  end
end
