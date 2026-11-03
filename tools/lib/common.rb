# frozen_string_literal: true

# Shared helpers for the NITC Protest Ops tools.
# Ruby stdlib only — no gems, no Bundler.

require "fileutils"
require "date"
require "json"
require "open3"
require "shellwords"
require "time"
require "yaml"

module Common
  module_function

  # Repository root = two levels above tools/lib.
  def root
    @root ||= File.expand_path("../..", __dir__)
  end

  def load_yaml(path)
    raise "no such brief: #{path}" unless File.file?(path)

    data = YAML.safe_load(File.read(path), permitted_classes: [Date, Time], aliases: true)
    raise "brief is empty: #{path}" unless data.is_a?(Hash)

    data
  end

  def slugify(value)
    value.to_s.downcase.strip
         .gsub(/[^a-z0-9]+/, "-")
         .gsub(/\A-+|-+\z/, "")
  end

  def html_escape(value)
    value.to_s
         .gsub("&", "&amp;")
         .gsub("<", "&lt;")
         .gsub(">", "&gt;")
         .gsub('"', "&quot;")
         .gsub("'", "&#39;")
  end

  # Newlines in copy become explicit line breaks, but never raw HTML.
  def html_lines(value)
    html_escape(value).split("\n", -1).join("<br>")
  end

  def which(command)
    ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |dir|
      candidate = File.join(dir, command)
      return candidate if File.executable?(candidate) && !File.directory?(candidate)
    end
    nil
  end

  def require_command!(command, hint = nil)
    return if which(command)

    message = "required command not found: #{command}"
    message += "\n#{hint}" if hint
    raise message
  end

  def run!(*args, chdir: root)
    command = args.flatten.map(&:to_s)
    stdout, stderr, status = Open3.capture3(*command, chdir: chdir)
    unless status.success?
      raise "command failed (#{status.exitstatus}): #{command.shelljoin}\n#{stderr}"
    end
    stdout
  end

  def run_quiet!(*args, chdir: root)
    command = args.flatten.map(&:to_s)
    _stdout, stderr, status = Open3.capture3(*command, chdir: chdir)
    return true if status.success?

    warn "command failed (#{status.exitstatus}): #{command.shelljoin}\n#{stderr}"
    false
  end

  # ── palettes ────────────────────────────────────────────────────────────────

  PALETTES = {
    "black" => { bg: "#000000", fg: "#FFFFFF", accent: "#E10600", muted: "#A3A3A3" },
    "white" => { bg: "#FFFFFF", fg: "#000000", accent: "#E10600", muted: "#4D4D4D" },
    "red"   => { bg: "#E10600", fg: "#000000", accent: "#FFFFFF", muted: "#2B0000" }
  }.freeze

  def palette(name)
    PALETTES.fetch(name.to_s.downcase, PALETTES["black"])
  end

  # ── rendering ───────────────────────────────────────────────────────────────

  # CSS shared by every renderer. Kept deliberately small: three colours,
  # two type families, one accent rule.
  def base_css(width:, height:)
    <<~CSS
      @page { size: #{width}px #{height}px; margin: 0; }
      * { box-sizing: border-box; }
      html, body { margin: 0; padding: 0; }
      body {
        -weasy-hyphens: none;
        font-family: "Liberation Sans", "DejaVu Sans", sans-serif;
        -weasy-font-variant-ligatures: none;
      }
      .panel {
        position: relative;
        width: #{width}px;
        height: #{height}px;
        overflow: hidden;
        background: var(--bg);
        color: var(--fg);
      }
      .masthead {
        position: absolute; top: 0; left: 0; right: 0;
        height: 96px; background: var(--accent);
        display: flex; align-items: center; justify-content: space-between;
        padding: 0 64px;
      }
      .masthead .kicker {
        font-family: "Liberation Sans Narrow", "DejaVu Sans Condensed", sans-serif;
        font-weight: 700; font-size: 26px; letter-spacing: 0.14em;
        text-transform: uppercase; color: var(--bg);
        white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        max-width: 780px;
      }
      .masthead .index {
        font-family: "Liberation Sans Narrow", "DejaVu Sans Condensed", sans-serif;
        font-weight: 700; font-size: 28px; letter-spacing: 0.04em;
        color: var(--bg); white-space: nowrap;
      }
      .body-wrap { position: absolute; left: 64px; right: 64px; top: 168px; }
      .headline {
        font-family: "Liberation Sans", "DejaVu Sans", sans-serif;
        font-weight: 900; text-transform: uppercase;
        letter-spacing: -0.025em; line-height: 0.96;
        margin: 0 0 36px 0;
      }
      .headline .accent { color: var(--accent); }
      .rule { width: 120px; height: 2px; background: var(--accent); margin: 0 0 26px 0; }
      .copy {
        font-size: 30px; line-height: 1.34; max-width: 936px;
        color: var(--fg); margin: 0;
      }
      .copy strong { color: var(--accent); }
      .bars { margin-top: 30px; }
      .bar {
        background: var(--accent); color: var(--bg);
        font-family: "Liberation Sans Narrow", "DejaVu Sans Condensed", sans-serif;
        font-weight: 700; font-size: 26px; letter-spacing: 0.04em;
        text-transform: uppercase; padding: 12px 18px; margin-bottom: 10px;
        width: 936px;
      }
      .footer {
        position: absolute; left: 64px; right: 64px; bottom: 44px;
        font-family: "Liberation Sans Narrow", "DejaVu Sans Condensed", sans-serif;
        font-weight: 700; font-size: 20px; letter-spacing: 0.06em;
        text-transform: uppercase; color: var(--accent);
      }
      .prompt {
        position: absolute; left: 64px; right: 64px; bottom: 44px;
        font-family: "Liberation Sans Narrow", "DejaVu Sans Condensed", sans-serif;
        font-weight: 700; font-size: 24px; letter-spacing: 0.08em;
        text-transform: uppercase; color: var(--accent); text-align: right;
      }
      .footer.with-prompt { bottom: 96px; }
      .side-rule {
        position: absolute; left: 40px; top: 168px; width: 10px;
        background: var(--accent);
      }
      .note { font-size: 20px; color: var(--muted); margin-top: 18px; }
    CSS
  end

  def write_html(path, html)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, html)
    path
  end

  # Render HTML → PDF → PNG at exactly `width` × `height` pixels.
  # Uses WeasyPrint + poppler; no browser, no ImageMagick PDF policy issues.
  def render_html(html_path, out_png, width:, height:)
    require_command!("weasyprint", "Run `nix develop` first.")
    require_command!("pdftoppm", "Install poppler_utils (`nix develop`).")

    pdf_path = out_png.sub(/\.png\z/, ".pdf")
    FileUtils.mkdir_p(File.dirname(out_png))
    run!("weasyprint", html_path, pdf_path)

    dpi = 96
    prefix = out_png.sub(/\.png\z/, "")
    run!("pdftoppm", "-png", "-r", dpi.to_s, "-singlefile", pdf_path, prefix)
    FileUtils.rm_f(pdf_path)

    actual = image_size(out_png)
    unless actual == [width, height]
      warn "warning: rendered #{actual.inspect}, expected #{[width, height].inspect} (#{out_png})"
    end
    out_png
  end

  def render_html_pages(html_path, out_dir, width:, height:)
    require_command!("weasyprint", "Run `nix develop` first.")
    require_command!("pdftoppm", "Install poppler_utils (`nix develop`).")

    FileUtils.mkdir_p(out_dir)
    pdf_path = File.join(out_dir, "_deck.pdf")
    run!("weasyprint", html_path, pdf_path)

    prefix = File.join(out_dir, "panel")
    run!("pdftoppm", "-png", "-r", "96", pdf_path, prefix)
    FileUtils.rm_f(pdf_path)

    Dir.glob(File.join(out_dir, "panel-*.png")).sort_by do |path|
      File.basename(path)[/panel-(\d+)\.png\z/, 1].to_i
    end
  end

  def image_size(path)
    require_command!("magick", "Install imagemagick (`nix develop`).")
    out = run!("magick", "identify", "-format", "%w %h", "#{path}[0]")
    out.split.map(&:to_i)
  end

  def contact_sheet(glob, out_path, columns: 5, tile: "360x360")
    require_command!("magick", "Install imagemagick (`nix develop`).")
    FileUtils.mkdir_p(File.dirname(out_path))
    files = Dir.glob(glob).sort
    raise "no images matched #{glob}" if files.empty?

    run!("magick", "montage", *files,
         "-tile", "#{columns}x",
         "-geometry", "#{tile}+12+12",
         "-background", "#111111",
         out_path)
    out_path
  end
end
