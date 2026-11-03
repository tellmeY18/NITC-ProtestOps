#!/usr/bin/env ruby
# frozen_string_literal: true

# Scrape the public index of Senate minutes into the local cache.
#
#   ruby tools/scrape/senate.rb --out research/senate
#   ruby tools/scrape/senate.rb --out research/senate --limit 5 --dry-run
#
# The cache is git-ignored: minutes contain student names, roll numbers and
# contact details. Publish only reviewed, non-personal excerpts.

require "optparse"
require_relative "index_scraper"

INDEX_URL = "https://nitc.ac.in/minutes-and-reports/senate-minutes"

options = {
  out: File.join(Common.root, "research", "senate"),
  url: INDEX_URL,
  limit: nil,
  delay: 1.0,
  force: false,
  dry_run: false
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby tools/scrape/senate.rb [--out DIR] [--url URL] [--limit N] [--delay SEC] [--force] [--dry-run]"
  opts.on("--out DIR", "Cache directory (default research/senate)") { |v| options[:out] = v }
  opts.on("--url URL", "Index page or direct PDF") { |v| options[:url] = v }
  opts.on("--limit N", Integer, "Only the first N links") { |v| options[:limit] = v }
  opts.on("--delay SEC", Float, "Delay between requests") { |v| options[:delay] = v }
  opts.on("--force", "Re-download cached files") { options[:force] = true }
  opts.on("--dry-run", "List links without downloading") { options[:dry_run] = true }
end.parse!

Scrape.run(
  index_url: options[:url],
  out_dir: options[:out],
  limit: options[:limit],
  delay: options[:delay],
  force: options[:force],
  dry_run: options[:dry_run]
)
