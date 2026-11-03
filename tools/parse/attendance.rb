#!/usr/bin/env ruby
# frozen_string_literal: true

# Summarise attendance from extracted Senate/BoG minutes.
#
#   ruby tools/parse/attendance.rb research/senate/93.txt
#   ruby tools/parse/attendance.rb research/senate/93.txt --names   # LOCAL ONLY
#
# By default this prints COUNTS ONLY — no names, no roll numbers. That is the
# safe output. `--names` is for local verification and must never be committed.

require "json"
require "optparse"
require_relative "../lib/common"

ROLL = /\b[A-Z][0-9]{6,7}[A-Z]{0,3}\b/
EMAIL = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/
PHONE = /(?:\+91[\s-]?)?\b[6-9][0-9]{9}\b/

options = { out: nil, names: false }
OptionParser.new do |opts|
  opts.banner = "Usage: ruby tools/parse/attendance.rb FILE.txt [--out FILE.json] [--names]"
  opts.on("--out FILE", "Write the summary as JSON") { |v| options[:out] = v }
  opts.on("--names", "Include matched identifiers (LOCAL ONLY — never commit)") { options[:names] = true }
end.parse!

input = ARGV.shift
abort "usage: ruby tools/parse/attendance.rb FILE.txt [--out FILE.json] [--names]" unless input
abort "no such file: #{input}" unless File.file?(input)

text = File.read(input, encoding: "UTF-8").scrub

rolls = text.scan(ROLL).uniq
emails = text.scan(EMAIL).uniq
phones = text.scan(PHONE).uniq

summary = {
  "file" => File.basename(input),
  "checked_at" => Time.now.utc.iso8601,
  "counts" => {
    "roll_numbers" => rolls.length,
    "emails" => emails.length,
    "phones" => phones.length
  },
  "note" => "Counts only. Raw identifiers are personal data and must stay local."
}

summary["identifiers"] = { "roll_numbers" => rolls, "emails" => emails, "phones" => phones } if options[:names]

if options[:names]
  warn "WARNING: --names includes personal data. Do not commit this output."
end

json = JSON.pretty_generate(summary)
puts json

if options[:out]
  FileUtils.mkdir_p(File.dirname(options[:out]))
  File.write(options[:out], json)
  puts "\nwrote #{options[:out]}"
end
