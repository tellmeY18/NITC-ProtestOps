#!/usr/bin/env ruby
# frozen_string_literal: true

# Check exported images: dimensions, metadata, weight, filenames.
#
#   ruby tools/audit/image_check.rb outputs/
#   ruby tools/audit/image_check.rb outputs/ --strict
#
# Warns on EXIF (which can carry a device, a time and a location), unexpected
# sizes, and very large files.

require "optparse"
require_relative "../lib/common"

options = { strict: false, expected: %w[1080x1080 1080x1920] }
OptionParser.new do |opts|
  opts.banner = "Usage: ruby tools/audit/image_check.rb [DIR] [--strict]"
  opts.on("--strict", "Treat warnings as failures") { options[:strict] = true }
end.parse!

dir = File.expand_path(ARGV.shift || File.join(Common.root, "outputs"))
abort "no such directory: #{dir}" unless File.directory?(dir)
Common.require_command!("magick", "Install imagemagick (`nix develop`).")

images = Dir.glob(File.join(dir, "**", "*.{png,jpg,jpeg,webp}")).sort
if images.empty?
  puts "no images under #{dir}"
  exit 0
end

errors = []
warnings = []

images.each do |path|
  relative = path.sub(%r{\A#{Regexp.escape(dir)}/}, "")
  format = Common.run!("magick", "identify", "-format", "%m", "#{path}[0]").strip
  width, height = Common.image_size(path)
  size = "#{width}x#{height}"
  bytes = File.size(path)

  errors << "#{relative}: filename contains spaces" if relative.include?(" ")
  errors << "#{relative}: zero dimensions" unless width.positive? && height.positive?

  unless options[:expected].include?(size)
    warnings << "#{relative}: #{size} (not one of #{options[:expected].join(', ')})"
  end

  warnings << "#{relative}: #{format} is not PNG" unless format == "PNG"
  warnings << "#{relative}: #{bytes / 1024} KiB is large" if bytes > 4_000_000

  exif = Common.run!("magick", "identify", "-format", "%[EXIF:*]", "#{path}[0]").strip
  unless exif.empty? || exif == "%[EXIF:*]"
    warnings << "#{relative}: contains EXIF metadata (strip before publishing)"
  end
end

puts "image check: #{images.length} image(s) under #{dir}"
puts

if errors.empty?
  puts "  ✓ dimensions and filenames are valid"
else
  puts "  ✗ #{errors.length} error(s):"
  errors.each { |e| puts "    - #{e}" }
end

unless warnings.empty?
  puts
  puts "  warnings:"
  warnings.first(40).each { |w| puts "    · #{w}" }
  puts "    … #{warnings.length - 40} more" if warnings.length > 40
end

exit 1 unless errors.empty?
exit 1 if options[:strict] && !warnings.empty?
