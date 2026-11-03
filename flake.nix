{
  description = "NITC Protest Ops — scrape, verify, design and publish student-governance documents";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          name = "nitc-protest-ops";

          packages = with pkgs; [
            # language and tooling
            ruby
            jq
            ripgrep
            git
            gh
            shellcheck
            curl
            unzip
            zstd

            # documents
            poppler-utils      # pdftotext, pdfinfo, pdftoppm
            tesseract          # OCR for scanned minutes

            # rendering
            python3Packages.weasyprint  # HTML/CSS → PDF, no browser required
            imagemagick        # contact sheets, crops, metadata
            qrencode           # QR codes for source panels
            fontconfig

            # open font substitutes (never commit the licensed originals)
            dejavu_fonts
            liberation_ttf
            noto-fonts
          ];

          shellHook = ''
            export PROJECT_ROOT="$PWD"
            export FONTCONFIG_FILE="${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
            export FONTCONFIG_PATH="${pkgs.fontconfig.out}/etc/fonts"

            echo ""
            echo "  NITC Protest Ops"
            echo "  ─────────────────────────────────────────────"
            echo "  ruby        $(ruby --version | cut -d' ' -f2)"
            echo "  weasyprint  $(weasyprint --version)"
            echo "  pdftotext   $(pdftotext -v 2>&1 | head -1 | cut -d' ' -f3)"
            echo "  magick      $(magick -version | head -1 | cut -d' ' -f3)"
            echo ""
            echo "  make a poster   ruby tools/render/poster.rb templates/poster/example.yml"
            echo "  audit the tree  ruby tools/audit/sensitive_scan.rb ."
            echo "  read the rules  AGENTS.md ETHICS.md FACTCHECK.md"
            echo ""
          '';
        };
      });

      # `nix fmt` — keeps Ruby, Nix, YAML and Markdown tidy without extra config.
      formatter = forAllSystems (pkgs: pkgs.nixpkgs-fmt);
    };
}
