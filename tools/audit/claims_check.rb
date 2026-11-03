#!/usr/bin/env ruby
# frozen_string_literal: true

# Validate claim tables.
#
#   ruby tools/audit/claims_check.rb analysis/sac-to-sgb/claims.yml
#   ruby tools/audit/claims_check.rb analysis/**/claims.yml
#
# Rules:
#   - every row has id, claim, source, locator, strength, checked
#   - strength is one of the six labels
#   - a quote is only allowed on a verbatim row
#   - a paraphrase/inference/opinion row must not contain quotation marks
#   - the checked date is ISO 8601

require "date"
require "optparse"
require_relative "../lib/common"

STRENGTHS = %w[verbatim documented reported paraphrase inference opinion].freeze

options = { strict: false }
OptionParser.new do |opts|
  opts.banner = "Usage: ruby tools/audit/claims_check.rb FILE.yml [FILE.yml ...]"
  opts.on("--strict", "Treat missing locators as errors") { options[:strict] = true }
end.parse!

paths = ARGV.flat_map { |arg| Dir.glob(arg) }.uniq
abort "usage: ruby tools/audit/claims_check.rb FILE.yml [...]" if paths.empty?

errors = []
warnings = []
total = 0

paths.each do |path|
  unless File.file?(path)
    errors << "#{path}: no such file"
    next
  end

  data = Common.load_yaml(path)
  rows = data["claims"]
  unless rows.is_a?(Array)
    errors << "#{path}: expected a top-level `claims:` list"
    next
  end

  rows.each_with_index do |row, index|
    total += 1
    where = "#{path}:#{index + 1}"
    id = row["id"] || "(no id)"
    label = "#{where} (#{id})"

    %w[id claim source locator strength checked].each do |field|
      value = row[field].to_s.strip
      if value.empty?
        if field == "locator"
          if options[:strict]
            errors << "#{label}: missing locator"
          else
            warnings << "#{label}: missing locator"
          end
        else
          errors << "#{label}: missing #{field}"
        end
      end
    end

    strength = row["strength"].to_s.strip
    unless STRENGTHS.include?(strength)
      errors << "#{label}: invalid strength #{strength.inspect} (use #{STRENGTHS.join('|')})"
      next
    end

    quote = row["quote"].to_s
    if !quote.empty? && strength != "verbatim"
      errors << "#{label}: has a quote but strength is #{strength}; only verbatim may quote"
    end

    claim = row["claim"].to_s
    if strength != "verbatim" && claim.match?(/["“”]/)
      warnings << "#{label}: #{strength} claim contains quotation marks; make sure they are not attributed to the source"
    end

    checked = row["checked"].to_s
    unless checked.empty?
      begin
        Date.iso8601(checked)
      rescue ArgumentError
        errors << "#{label}: checked date is not ISO 8601 (#{checked})"
      end
    end

    source = row["source"].to_s
    if source.match?(/\Ahttps?:\/\//)
      warnings << "#{label}: source is a URL; record the clause/page in locator"
    end
  end
end

puts "claims check: #{total} claim(s) across #{paths.length} file(s)"
puts

if errors.empty?
  puts "  ✓ every claim has a source, a locator and a valid strength"
else
  puts "  ✗ #{errors.length} error(s):"
  errors.each { |e| puts "    - #{e}" }
end

unless warnings.empty?
  puts
  puts "  warnings:"
  warnings.each { |w| puts "    · #{w}" }
end

exit 1 unless errors.empty?
