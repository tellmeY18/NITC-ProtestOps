#!/usr/bin/env ruby
# frozen_string_literal: true

# Fetch the SAC (2008) and SGB (2024) constitutions from archive.org.
#
#   ruby tools/scrape/constitution.rb --out research
#   ruby tools/scrape/constitution.rb --id sac-constitution --text
#
# Uses the archive.org metadata API, so it does not depend on page scraping.

require "json"
require "optparse"
require "uri"
require_relative "../lib/common"

DEFAULTS = {
  "sac-constitution" => "SAC Constitution (2008)",
  "sgb-constitution" => "SGB Constitution (2024)"
}.freeze

options = { out: File.join(Common.root, "research"), id: nil, text: false, force: false }
OptionParser.new do |opts|
  opts.banner = "Usage: ruby tools/scrape/constitution.rb [--id ID] [--out DIR] [--text] [--force]"
  opts.on("--id ID", "Archive.org identifier (default: both)") { |v| options[:id] = v }
  opts.on("--out DIR", "Cache directory") { |v| options[:out] = v }
  opts.on("--text", "Prefer the DjVu text over the PDF") { options[:text] = true }
  opts.on("--force", "Re-download") { options[:force] = true }
end.parse!

ids = options[:id] ? [options[:id]] : DEFAULTS.keys
FileUtils.mkdir_p(options[:out])

ids.each do |id|
  puts "== #{DEFAULTS[id] || id} (#{id})"
  metadata_url = "https://archive.org/metadata/#{id}"
  raw = Common.run!("curl", "-fsSL", "--max-time", "60", metadata_url)
  data = JSON.parse(raw)

  files = Array(data["files"])
  wanted =
    if options[:text]
      files.find { |f| f["name"].to_s.end_with?("_djvu.txt") } ||
        files.find { |f| f["name"].to_s.downcase.end_with?(".pdf") }
    else
      files.find { |f| f["name"].to_s.downcase.end_with?(".pdf") } ||
        files.find { |f| f["name"].to_s.end_with?("_djvu.txt") }
    end

  unless wanted
    warn "  no PDF or DjVu text found in metadata"
    next
  end

  name = File.basename(wanted["name"])
  target = File.join(options[:out], name)

  if File.file?(target) && !options[:force]
    puts "  skip  #{name} (cached)"
    next
  end

  encoded = URI.encode_www_form_component(name).gsub("+", "%20")
  url = "https://archive.org/download/#{id}/#{encoded}"
  puts "  fetch #{name}"
  Common.run!("curl", "-fsSL", "--max-time", "120", "-o", target, url)
  puts "  saved #{target} (#{File.size(target)} bytes)"
end
