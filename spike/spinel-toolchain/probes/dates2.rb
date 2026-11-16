require "yaml"
require "date"
["date: 2026-11-15", "time: 2026-11-15 10:30:00 +00:00", "anchor: &x {k: v}\nref: *x"].each do |d|
  begin
    p YAML.safe_load(d, permitted_classes: [Date, Time], aliases: true)
  rescue Exception => e
    puts "permitted raised #{e.class}: #{e.message}"
  end
  begin
    p YAML.unsafe_load(d)
  rescue Exception => e
    puts "unsafe_load raised #{e.class}: #{e.message}"
  end
end
