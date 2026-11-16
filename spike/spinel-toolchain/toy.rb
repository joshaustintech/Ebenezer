require "yaml"
require "fileutils"

FM = /\A---\s*\n(.*?)\n---\s*\n/m

def escape(s)
  s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
end

def render(body)
  out = []
  body.split("\n\n").each do |para|
    para = para.strip
    next if para.empty?
    if para.start_with?("# ")
      out << "<h1>" + escape(para[2..]) + "</h1>"
    else
      out << "<p>" + escape(para).gsub(/\*(.+?)\*/) { "<em>" + $1 + "</em>" } + "</p>"
    end
  end
  out.join("\n")
end

src = ARGV[0] || "site"
dest = ARGV[1] || "out"
count = 0
Dir.glob(src + "/**/*").sort.each do |path|
  next unless File.file?(path)
  rel = path[(src.length + 1)..]
  text = File.read(path)
  m = FM.match(text)
  if m
    fm = YAML.safe_load(m[1])
    title = fm["title"].to_s
    tags = fm["tags"]
    body = text[m[0].length..]
    html = "<!doctype html>\n<title>" + escape(title) + "</title>\n" + render(body) + "\n"
    html += "<p>tags: " + tags.join(", ") + "</p>\n" if tags.is_a?(Array)
    target = File.join(dest, rel.sub(/\.md\z/, ".html"))
  else
    html = text
    target = File.join(dest, rel)
  end
  FileUtils.mkdir_p(File.dirname(target))
  File.write(target, html)
  count += 1
end
puts "wrote #{count} files"
