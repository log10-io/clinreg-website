.PHONY: help publish serve check

HTML ?=
CSV  ?=
PORT ?= 8000

help:
	@echo "make publish HTML=output.html [CSV=data.csv]  Publish a leaderboard"
	@echo "make serve [PORT=8000]                        Preview site/ locally"
	@echo "make check                                    Verify site/ is deployable"

publish:
	@test -n "$(HTML)" || { echo "usage: make publish HTML=output.html [CSV=data.csv]"; exit 2; }
	@./scripts/publish.sh $(if $(SNAPSHOT),--snapshot) "$(HTML)" $(if $(CSV),"$(CSV)")

serve:
	@echo "http://localhost:$(PORT)"
	@cd site && python3 -m http.server $(PORT)

# Guards the two files that are easy to delete by accident and whose absence
# breaks the site quietly: CNAME (custom domain) and .nojekyll (underscore paths).
check:
	@test -f site/index.html || { echo "missing site/index.html"; exit 1; }
	@test -f site/CNAME      || { echo "missing site/CNAME"; exit 1; }
	@test -f site/.nojekyll  || { echo "missing site/.nojekyll"; exit 1; }
	@echo "site/ looks deployable ($$(du -sh site | cut -f1))"
