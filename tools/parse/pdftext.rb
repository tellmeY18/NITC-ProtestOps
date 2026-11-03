#!/usr/bin/env ruby
# frozen_string_literal: true

# Extract text from a PDF with poppler, and refuse to pretend an HTML error
# page is a document.
#
#   ruby tools/parse/pdftext.rb research/senate/93.pdf
#   ruby tools/parse/pdftext.rb research/senate/93.pdf --out research/notes/senate-93.txt

require "optparse"
require_relative "../lib/common"

options = { out: nil, stdout: false }
OptionParser.new do |opts|
  opts.banner = "Usage: ruby tools/parse/pdftext.rb FILE.pdf [--out FILE.txt] [--stdout]"
  opts.on("--out FILE", "Write text to FILE") { |v| options[:out] = v }
  opts.on("--stdout", "Print text to stdout") { options[:stdout] = true }
end.parse!

input = ARGV.shift
abort "usage: ruby tools/parse/pdftext.rb FILE.pdf [--out FILE.txt]" unless input
abort "no such file: #{input}" unless File.file?(input)

unless File.binread(input, 5) == "%PDF-"
  warn "#{input} is not a PDF (first bytes: #{File.binread(input, 16).inspect})"
  warn "Institute sites sometimes serve an HTML error page with a .pdf name."
  exit 2
end

Common.require_command!("pdftotext", "Install poppler_utils (`nix develop`).")

target = options[:out] || input.sub(/\.pdf\z/i, ".txt")
Common.run!("pdftotext", "-layout", "-enc", "UTF-8", input, target)

text = File.binread(target).force_encoding("UTF-8").scrub
nulls = text.count("\0")
replacement = text.count("\uFFFD")
words = text.split(/\s+/).reject(&:empty?).length

puts "wrote #{target}"
puts "  #{words} words, #{nulls} null bytes, #{replacement} replacement characters"

if nulls.positive? || words < 20
  warn "  warning: the text layer looks broken. The PDF may be a scan or have a"
  warn "  broken font encoding. Run OCR (tesseract) before relying on it."
end

if options[:stdout]
  puts
  puts text
end
