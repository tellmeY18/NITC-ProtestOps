#!/usr/bin/env ruby
# frozen_string_literal: true

# Render the reading-circle story template (1080x1920) with a QR code.
#
#   ruby tools/render/reading_circle.rb templates/reading-circle/brief.yml
#   ruby tools/render/reading_circle.rb templates/reading-circle/brief.yml \
#        --when "FRI 6 PM" --where "OAT" --out outputs/_review/my-circle.png
#
# Leave --when / --where empty to get the blank fill-in version.

require "optparse"
require_relative "../lib/common"

options = { out: nil, when: nil, where: nil }
OptionParser.new do |opts|
  opts.banner = "Usage: ruby tools/render/reading_circle.rb BRIEF.yml [--when T] [--where P] [--out PATH]"
  opts.on("--when TEXT", "Time, e.g. 'FRI 6 PM'") { |v| options[:when] = v }
  opts.on("--where TEXT", "Place, e.g. 'OAT'") { |v| options[:where] = v }
  opts.on("--out PATH", "Output PNG") { |v| options[:out] = v }
end.parse!

brief_path = ARGV.shift or abort "usage: ruby tools/render/reading_circle.rb BRIEF.yml"
brief = Common.load_yaml(brief_path)

width = 1080
height = 1920
slug = Common.slugify(brief["slug"] || "reading-circle")
out = options[:out] || File.join(Common.root, "outputs", "_review", "#{slug}.png")

Common.require_command!("qrencode", "Run `nix develop` first.")
tmp_dir = File.join(Common.root, "tmp")
FileUtils.mkdir_p(tmp_dir)
qr_path = File.join(tmp_dir, "#{slug}-qr.png")
Common.run!("qrencode", "-t", "PNG", "-s", "12", "-m", "2", "-l", "M", "-o", qr_path, brief.fetch("qr_url"))

def accent_lines(value)
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

when_text = (options[:when] || brief["when"]).to_s.strip
where_text = (options[:where] || brief["where"]).to_s.strip

field = lambda do |label, value|
  filled = value.empty? ? "" : " filled"
  %(<div class="field"><span class="flabel">#{label}</span><span class="fline#{filled}">#{Common.html_escape(value)}</span></div>)
end

steps = Array(brief["steps"]).map { |s| %(<div class="bar">#{Common.html_escape(s)}</div>) }.join("\n")
places = Array(brief["places"]).map { |p| %(<span class="chip">#{Common.html_escape(p)}</span>) }.join("\n")
palette = Common.palette("black")

html = <<~HTML
  <!doctype html>
  <html lang="en"><head><meta charset="utf-8">
  <title>#{Common.html_escape(brief["kicker"])}</title>
  <style>
    :root { --bg: #{palette[:bg]}; --fg: #{palette[:fg]}; --accent: #{palette[:accent]}; --muted: #{palette[:muted]}; }
    #{Common.base_css(width: width, height: height)}
    .band { position: absolute; top: 0; left: 0; right: 0; height: 40px; background: var(--accent); }
    .kicker2 {
      position: absolute; left: 64px; top: 190px;
      font-family: "Liberation Sans Narrow", "DejaVu Sans Condensed", sans-serif;
      font-weight: 700; font-size: 30px; letter-spacing: 0.14em; color: var(--accent);
    }
    .h { position: absolute; left: 64px; top: 240px; font-size: 150px; margin: 0; }
    .b { position: absolute; left: 64px; top: 560px; width: 936px; }
    .b .rule { margin-bottom: 20px; }
    .b .copy { font-size: 28px; line-height: 1.32; }
    .steps { position: absolute; left: 64px; top: 760px; width: 936px; }
    .steps .bar { font-size: 25px; margin-bottom: 8px; }
    .chips { position: absolute; left: 64px; top: 1030px; width: 936px; }
    .chip {
      display: inline-block; border: 2px solid var(--fg); color: var(--fg);
      font-family: "Liberation Sans Narrow", "DejaVu Sans Condensed", sans-serif;
      font-weight: 700; font-size: 22px; letter-spacing: 0.08em;
      padding: 6px 14px; margin: 0 8px 8px 0;
    }
    .fields { position: absolute; left: 64px; top: 1160px; width: 936px; background: #fff; color: #000; padding: 18px 24px 8px; }
    .field { display: flex; align-items: flex-end; margin-bottom: 14px; }
    .flabel {
      width: 150px; font-family: "Liberation Sans Narrow", "DejaVu Sans Condensed", sans-serif;
      font-weight: 700; font-size: 30px; letter-spacing: 0.1em; color: #000;
    }
    .fline { flex: 1; border-bottom: 3px solid #000; height: 44px; font-weight: 700; font-size: 32px; text-transform: uppercase; }
    .slogan {
      position: absolute; left: 64px; top: 1360px; width: 936px;
      background: var(--accent); color: #000; padding: 12px 20px;
      font-weight: 900; font-size: 54px; letter-spacing: -0.01em; text-transform: uppercase;
    }
    .qr { position: absolute; left: 64px; top: 1470px; width: 230px; height: 230px; background: #fff; padding: 8px; }
    .qr img { width: 214px; height: 214px; display: block; }
    .qtext { position: absolute; left: 320px; top: 1470px; width: 680px; }
    .qtext .l1 { font-family: "Liberation Sans Narrow", "DejaVu Sans Condensed", sans-serif; font-weight: 700; font-size: 34px; letter-spacing: 0.08em; color: var(--accent); }
    .qtext .l2 { font-size: 22px; color: var(--muted); margin: 4px 0 14px; word-break: break-all; }
    .qtext .l3 { font-family: "Liberation Sans Narrow", "DejaVu Sans Condensed", sans-serif; font-weight: 700; font-size: 25px; letter-spacing: 0.05em; line-height: 1.25; }
    .qtext .l4 { margin-top: 12px; font-family: "Liberation Sans Narrow", "DejaVu Sans Condensed", sans-serif; font-weight: 700; font-size: 25px; letter-spacing: 0.05em; color: var(--accent); }
  </style></head>
  <body><section class="panel">
    <div class="band"></div>
    <div class="kicker2">#{Common.html_escape(brief["kicker"])}</div>
    <h1 class="headline h">#{accent_lines(brief["headline"])}</h1>
    <div class="b"><div class="rule"></div><p class="copy">#{Common.html_lines(brief["body"].to_s.strip)}</p></div>
    <div class="steps">#{steps}</div>
    <div class="chips">#{places}</div>
    <div class="fields">#{field.call("WHEN", when_text)}#{field.call("WHERE", where_text)}</div>
    <div class="slogan">#{Common.html_escape(brief["slogan"])}</div>
    <div class="qr"><img src="file://#{qr_path}" alt="QR code"></div>
    <div class="qtext">
      <div class="l1">#{Common.html_escape(brief["qr_label"])}</div>
      <div class="l2">#{Common.html_escape(brief["qr_url"])}</div>
      <div class="l3">#{Common.html_escape(brief["rules"])}</div>
      <div class="l4">#{Common.html_escape(brief["tag_line"])}</div>
    </div>
  </section></body></html>
HTML

html_path = File.join(tmp_dir, "#{slug}.html")
Common.write_html(html_path, html)
Common.render_html(html_path, out, width: width, height: height)
FileUtils.rm_f([html_path, qr_path])
puts "wrote #{out}"
