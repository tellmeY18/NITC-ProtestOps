#!/usr/bin/env ruby
# frozen_string_literal: true

# Render a carousel (or a story set) from a YAML brief.
#
#   ruby tools/render/carousel.rb templates/carousel/example.yml
#   ruby tools/render/carousel.rb templates/story/example.yml --size 1080x1920
#
# Output: outputs/_review/<slug>/NN-slug.png + contact-sheet.png

require "optparse"
require_relative "../lib/common"

options = { size: nil, out: nil, columns: 5 }
OptionParser.new do |opts|
  opts.banner = "Usage: ruby tools/render/carousel.rb BRIEF.yml [--size WxH] [--out DIR]"
  opts.on("--size WxH", "Panel size, e.g. 1080x1920") { |v| options[:size] = v }
  opts.on("--out DIR", "Output directory") { |v| options[:out] = v }
  opts.on("--columns N", Integer, "Contact-sheet columns") { |v| options[:columns] = v }
end.parse!

brief_path = ARGV.shift
abort "usage: ruby tools/render/carousel.rb BRIEF.yml [--size WxH] [--out DIR]" unless brief_path

brief = Common.load_yaml(brief_path)
panels = brief["panels"]
abort "brief has no panels" unless panels.is_a?(Array) && !panels.empty?
abort "too many panels (#{panels.length}); Instagram's cap is 20" if panels.length > 20

slug = Common.slugify(brief["slug"] || File.basename(brief_path, ".*"))
size = options[:size] || brief["size"] || "1080x1080"
width, height = size.split("x").map(&:to_i)
abort "bad size: #{size}" unless width.positive? && height.positive?

out_dir = options[:out] || File.join(Common.root, "outputs", "_review", slug)

def format_headline(value)
  accent = false
  value.to_s.split(" / ").map do |line|
    line = line.strip
    opens = line.start_with?("**")
    closes = line.end_with?("**")
    line = line.sub(/\A\*\*/, "").sub(/\*\*\z/, "")
    accent = true if opens
    html = Common.html_escape(line)
    html = %(<span class="accent">#{html}</span>) if accent
    accent = false if closes
    html
  end.join("<br>")
end

def fit_size(value, max: 160, min: 64)
  lines = value.to_s.split(" / ")
  longest = lines.map(&:length).max || 1
  ideal = (936.0 / (longest * 0.56)).floor
  [[ideal, max].min, min].max
end

def panel_html(panel, number, total, width, height)
  palette = Common.palette(panel["inversion"] || panel["palette"] || "black")
  headline_size = fit_size(panel["headline"])
  index = panel["index"] || format("%02d/%02d", number, total)

  body = panel["body"].to_s.strip
  body_html = body.empty? ? "" : %(<p class="copy">#{Common.html_lines(body)}</p>)

  bars = Array(panel["bars"]).map do |bar|
    %(<div class="bar">#{Common.html_escape(bar)}</div>)
  end.join("\n")

  footer = panel["footer"].to_s.strip
  prompt = panel["prompt"].to_s.strip
  footer_class = prompt.empty? ? "footer" : "footer with-prompt"
  footer_html = footer.empty? ? "" : %(<div class="#{footer_class}">#{Common.html_escape(footer)}</div>)
  prompt_html = prompt.empty? ? "" : %(<div class="prompt">#{Common.html_escape(prompt)}</div>)

  kicker = panel["kicker"].to_s.strip

  <<~HTML
    <section class="panel" style="--bg: #{palette[:bg]}; --fg: #{palette[:fg]}; --accent: #{palette[:accent]}; --muted: #{palette[:muted]}; page-break-after: always;">
      <div class="masthead">
        <div class="kicker">#{Common.html_escape(kicker)}</div>
        <div class="index">#{Common.html_escape(index)}</div>
      </div>
      <div class="side-rule" style="height: #{headline_size * [panel["headline"].to_s.split(" / ").length, 1].max * 1.1}px;"></div>
      <div class="body-wrap">
        <h1 class="headline" style="font-size: #{headline_size}px;">#{format_headline(panel["headline"])}</h1>
        #{body_html.empty? ? "" : '<div class="rule"></div>'}
        #{body_html}
        #{bars.empty? ? "" : %(<div class="bars">#{bars}</div>)}
      </div>
      #{footer_html}
      #{prompt_html}
    </section>
  HTML
end

sections = panels.each_with_index.map do |panel, i|
  panel_html(panel, i + 1, panels.length, width, height)
end.join("\n")

html = <<~HTML
  <!doctype html>
  <html lang="en">
  <head>
    <meta charset="utf-8">
    <title>#{Common.html_escape(brief["title"] || slug)}</title>
    <style>
      #{Common.base_css(width: width, height: height)}
      .panel { page-break-after: always; }
      .panel:last-child { page-break-after: auto; }
    </style>
  </head>
  <body>
  #{sections}
  </body>
  </html>
HTML

tmp = File.join(Common.root, "tmp", "#{slug}.html")
Common.write_html(tmp, html)

FileUtils.rm_rf(out_dir)
pages = Common.render_html_pages(tmp, out_dir, width: width, height: height)
FileUtils.rm_f(tmp)

pages.each_with_index do |page, i|
  panel = panels[i]
  name = Common.slugify(panel["slug"] || panel["headline"].to_s.split(" / ").first)
  name = "panel" if name.empty?
  target = File.join(out_dir, format("%02d-%s.png", i + 1, name))
  FileUtils.mv(page, target)
end

sheet = Common.contact_sheet(File.join(out_dir, "*.png"),
                             File.join(Common.root, "outputs", "_review", "#{slug}-contact-sheet.png"),
                             columns: options[:columns],
                             tile: "360x360")

puts "wrote #{pages.length} panels to #{out_dir}"
puts "wrote contact sheet #{sheet}"
