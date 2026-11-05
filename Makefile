# Convenience targets. Everything here also works as a direct ruby command.

.PHONY: sources help audit claims poster carousel story clean

sources:
	ruby tools/scrape/fetch_sources.rb

help:
	@echo "make sources   fetch the full NITC PDF corpus into research/raw/sources"
	@echo "make audit      run the sensitive-data and claim-table checks"
	@echo "make poster     render templates/poster/example.yml"
	@echo "make carousel   render templates/carousel/example.yml"
	@echo "make story      render templates/story/example.yml at 1080x1920"
	@echo "make clean      remove tmp/ and generated PDFs"

audit:
	ruby tools/audit/sensitive_scan.rb .
	ruby tools/audit/claims_check.rb 'analysis/**/claims.yml'

claims:
	ruby tools/audit/claims_check.rb 'analysis/**/claims.yml'

poster:
	ruby tools/render/poster.rb templates/poster/example.yml

carousel:
	ruby tools/render/carousel.rb templates/carousel/example.yml

story:
	ruby tools/render/carousel.rb templates/story/example.yml --size 1080x1920

clean:
	rm -rf tmp
	find outputs -name '*.pdf' -delete
