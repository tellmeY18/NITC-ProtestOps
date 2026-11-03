#!/usr/bin/env ruby
# frozen_string_literal: true

# Render a single poster from a YAML brief.
#
#   ruby tools/render/poster.rb templates/poster/example.yml
#   ruby tools/render/poster.rb brief.yml --out outputs/_review/custom.png
#
# Output defaults to outputs/_review/<slug>.png at 1080×1080.

require "optparse"
require_relative "../lib/common"

options = { out: nil, size: nil }
OptionParser.new do |opts|
  opts.banner = "Usage: ruby tools/render/poster.rb BRIEF.yml [--out PATH] [--size WxH]"
  opts.on("--out PATH", "Output PNG path") { |v| options[:out] = v }
  opts.on("--size WxH", "Override size, e.g. 1080x1350") { |v| options[:size] = v }
end.parse!

brief_path = ARGV.shift
abort "usage: ruby tools/render/poster.rb BRIEF.yml [--out PATH] [--size WxH]" unless brief_path

brief = Common.load_yaml(brief_path)
slug = brief["slug"] || File.basename(brief_path, ".*")
size = options[:size] || brief["size"] || "1080x1080"
width, height = size.split("x").map(&:to_i)
abort "bad size: #{size}" unless width.positive? && height.positive?

palette = Common.palette(brief["palette"] || "black")
out = options[:out] || File.join(Common.root, "outputs", "_review", "#{Common.slugify(slug)}.png")

# Format a headline: " / " is a hard line break; **text** is the accent colour.
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

def fit_size(lines, max: 160, min: 72)
  longest = lines.map(&:length).max || 1
  # Rough metric for a heavy grotesque: ~0.56 em per character.
  ideal = (936.0 / (longest * 0.56)).floor
  [[ideal, max].min, min].max
end

headline_lines = brief["headline"].to_s.split(" / ")
headline_size = fit_size(headline_lines)

bars = Array(brief["bars"]).map do |bar|
  %(<div class="bar">#{Common.html_escape(bar)}</div>)
end.join("\n")

body = brief["body"].to_s.strip
body_html = body.empty? ? "" : %(<p class="copy">#{Common.html_lines(body)}</p>)
footer = brief["footer"].to_s.strip
footer_html = footer.empty? ? "" : %(<div class="footer">#{Common.html_escape(footer)}</div>)

html = <<~HTML
  <!doctype html>
  <html lang="en">
  <head>
    <meta charset="utf-8">
    <title>#{Common.html_escape(brief["title"] || slug)}</title>
    <style>
      :root {
        --bg: #{palette[:bg]};
        --fg: #{palette[:fg]};
        --accent: #{palette[:accent]};
        --muted: #{palette[:muted]};
      }
      #{Common.base_css(width: width, height: height)}
      .headline { font-size: #{headline_size}px; }
      .side-rule { height: #{headline_size * [headline_lines.length, 1].max * 1.1}px; }
    </style>
  </head>
  <body>
    <section class="panel">
      <div class="masthead">
        <div class="kicker">#{Common.html_escape(brief["kicker"])}</div>
        <div class="index">#{Common.html_escape(brief["index"] || "")}</div>
      </div>
      <div class="side-rule"></div>
      <div class="body-wrap">
        <h1 class="headline">#{format_headline(brief["headline"])}</h1>
        #{body_html.empty? ? "" : '<div class="rule"></div>'}
        #{body_html}
        #{bars.empty? ? "" : %(<div class="bars">#{bars}</div>)}
      </div>
      #{footer_html}
    </section>
  </body>
  </html>
HTML

tmp = File.join(Common.root, "tmp", "#{Common.slugify(slug)}.html")
Common.write_html(tmp, html)
Common.render_html(tmp, out, width: width, height: height)
FileUtils.rm_f(tmp)

puts "wrote #{out} (#{width}×#{height})"
