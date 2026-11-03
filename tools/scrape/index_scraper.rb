# frozen_string_literal: true

# Generic, polite index scraper for NITC minute pages.
#
# It fetches an index page, collects links to PDFs, and downloads them one at a
# time into a local cache. It never writes outside the cache, never retries more
# than twice, and refuses to save a file that is not a real PDF.

require "json"
require "time"
require "uri"
require_relative "../lib/common"

module Scrape
  USER_AGENT = "NITC-ProtestOps/0.1 (student research; contact via repository)"
  MAX_RETRIES = 2

  module_function

  def fetch(url, destination = nil)
    args = ["curl", "-fsSL", "--max-time", "90", "-A", USER_AGENT]
    args += ["-o", destination] if destination
    args << url
    Common.run!(*args)
  end

  def extract_pdf_links(html, base_url)
    links = html.scan(/href\s*=\s*["']([^"']+)["']/i).flatten
    links.map { |href| href.strip }
         .reject { |href| href.start_with?("#", "mailto:", "javascript:") }
         .select { |href| href.split("?").first.downcase.end_with?(".pdf") }
         .map { |href| URI.join(base_url, href).to_s }
         .uniq
  end

  def pdf?(path)
    File.file?(path) && File.binread(path, 5) == "%PDF-"
  end

  def run(index_url:, out_dir:, limit: nil, delay: 1.0, force: false, dry_run: false)
    FileUtils.mkdir_p(out_dir)
    manifest_path = File.join(out_dir, "manifest.json")
    manifest = File.file?(manifest_path) ? JSON.parse(File.read(manifest_path)) : []

    puts "fetching index: #{index_url}"
    html = fetch(index_url)
    links = extract_pdf_links(html, index_url)
    links = links.first(limit) if limit

    if links.empty?
      warn "no PDF links found. The page may be JavaScript-driven."
      warn "Pass --url with the direct PDF, or open the page and copy the link."
      return manifest
    end

    puts "found #{links.length} PDF link(s)"

    links.each_with_index do |url, index|
      name = File.basename(URI.parse(url).path)
      name = "document-#{index + 1}.pdf" if name.empty? || !name.downcase.end_with?(".pdf")
      target = File.join(out_dir, name)

      if File.file?(target) && !force
        puts "  skip   #{name} (cached)"
        next
      end

      if dry_run
        puts "  would  #{url}"
        next
      end

      puts "  fetch  #{name}"
      ok = false
      MAX_RETRIES.times do |attempt|
        begin
          fetch(url, target)
          ok = pdf?(target)
          break if ok

          warn "         not a PDF (probably an HTML error page); discarding"
          FileUtils.rm_f(target)
          break
        rescue StandardError => e
          warn "         attempt #{attempt + 1} failed: #{e.message.lines.first.strip}"
          sleep(delay)
        end
      end

      entry = {
        "file" => name,
        "url" => url,
        "fetched_at" => Time.now.utc.iso8601,
        "ok" => ok,
        "bytes" => ok ? File.size(target) : 0
      }

      manifest.reject! { |row| row["file"] == name }
      manifest << entry
      File.write(manifest_path, JSON.pretty_generate(manifest))

      sleep(delay) unless index == links.length - 1
    end

    puts "manifest: #{manifest_path}"
    manifest
  end
end
