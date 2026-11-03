#!/usr/bin/env ruby
# frozen_string_literal: true

# Pre-commit audit: make sure personal data, fonts and ignored paths did not
# sneak into the tree.
#
#   ruby tools/audit/sensitive_scan.rb .
#   ruby tools/audit/sensitive_scan.rb . --strict
#
# Exits non-zero when it finds something that must not be published.

require "optparse"
require_relative "../lib/common"

ROLL = /\b[A-Z][0-9]{6,7}[A-Z]{0,3}\b/
EMAIL = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/
PHONE = /(?:\+91[\s-]?)?\b[6-9][0-9]{9}\b/

BLOCKED_PATH = %r{
  \A(?:
    private/ |
    research/(?:senate|bog|raw|cache)/ |
    tmp/ |
    node_modules/ |
    \.git/
  ) |
  (?:^|/)\.DS_Store\z |
  (?:^|/)scan\.png\z |
  (?:^|/)WhatsApp\ Image |
  \.(?:ttf|otf|woff2?|eot)\z |
  \.(?:zip|tar|tgz|tar\.gz)\z |
  (?:^|/)\.env(?:\.|$) |
  \.(?:pem|key)\z
}xi

BINARY_EXT = %w[
  .png .jpg .jpeg .gif .webp .pdf .pcraft .zip .gz .tgz .ttf .otf .woff .woff2
  .mp4 .mov .mp3 .wav .ico .icns
].freeze

options = { strict: false, max_report: 25 }
OptionParser.new do |opts|
  opts.banner = "Usage: ruby tools/audit/sensitive_scan.rb [PATH] [--strict]"
  opts.on("--strict", "Treat warnings as failures") { options[:strict] = true }
  opts.on("--max-report N", Integer, "Max examples per category") { |v| options[:max_report] = v }
end.parse!

target = ARGV.shift || "."
root = File.expand_path(target)

def git_repo?(dir)
  _out, _err, status = Open3.capture3("git", "-C", dir, "rev-parse", "--is-inside-work-tree")
  status.success?
end

def tracked_files(dir)
  # Cached + untracked, minus anything matched by .gitignore. This is the set
  # that would actually be published, so an untracked font or PDF is caught
  # before it is staged.
  out, _err, status = Open3.capture3("git", "-C", dir, "ls-files", "-co", "--exclude-standard", "-z")
  return nil unless status.success?

  out.split("\0").reject(&:empty?)
end

def walk_files(dir)
  Dir.glob(File.join(dir, "**", "*"), File::FNM_DOTMATCH).map do |path|
    next unless File.file?(path)

    path.sub(%r{\A#{Regexp.escape(dir)}/}, "")
  end.compact
end

files =
  if git_repo?(root)
    tracked_files(root) || []
  else
    walk_files(root).reject { |p| p.match?(BLOCKED_PATH) || p.start_with?(".git/") }
  end

errors = []
warnings = []

# 1. Blocked paths that are tracked.
allowed_private = %w[private/.gitignore private/README.md]
blocked = files.select { |p| p.match?(BLOCKED_PATH) && !allowed_private.include?(p) }
blocked.each { |p| errors << "tracked path must not be published: #{p}" }

# 2. Content scan of text files.
content_hits = Hash.new { |h, k| h[k] = [] }

files.each do |relative|
  absolute = File.join(root, relative)
  next unless File.file?(absolute)
  next if BINARY_EXT.include?(File.extname(relative).downcase)
  next if File.size(absolute) > 4_000_000

  text = File.read(absolute, encoding: "UTF-8").scrub
  next if text.include?("\0")

  {
    "roll number" => ROLL,
    "email" => EMAIL,
    "phone" => PHONE
  }.each do |label, pattern|
    text.scan(pattern).uniq.each do |match|
      content_hits[label] << [relative, match]
    end
  end
end

content_hits.each do |label, hits|
  hits.each do |file, match|
    errors << "#{label} in #{file}: #{match}"
  end
end

# 3. Ignored directories that exist locally are fine; note them.
%w[private research/senate research/bog research/raw research/cache].each do |dir|
  warnings << "local-only cache present (git-ignored): #{dir}" if File.directory?(File.join(root, dir))
end

# 4. Report.
puts "sensitive scan: #{files.length} file(s) inspected under #{root}"
puts

if errors.empty?
  puts "  ✓ no personal data, fonts or blocked paths in the published tree"
else
  puts "  ✗ #{errors.length} finding(s):"
  errors.first(options[:max_report] * 4).each { |e| puts "    - #{e}" }
  puts "    … #{errors.length - options[:max_report] * 4} more" if errors.length > options[:max_report] * 4
end

unless warnings.empty?
  puts
  puts "  notes:"
  warnings.each { |w| puts "    · #{w}" }
end

exit 1 unless errors.empty?
exit 1 if options[:strict] && !warnings.empty?
