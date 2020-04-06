# Makefile to generate the extension out of separate sql source files.
# Once a version is released, it is not meant to be changed. E.g: once version 0.0.1 is out, it SHALL NOT be changed.
EXTENSION = cdb_dataservices_server
EXTVERSION = 0.38.0

# The new version to be generated from templates
SED ?= sed
ERB ?= erb
AWK ?= awk
PG_CONFIG ?= pg_config

# Parallel support macros
PG_CONFIG        ?= pg_config
PG_PARALLEL      := $(shell $(PG_CONFIG) --version | ($(AWK) '{$$2*=1000; if ($$2 >= 9600) print 1; else print 0;}' 2> /dev/null || echo 0))

# PG12 compatibility
PG_VERSION := $(shell $(PG_CONFIG) --version | $(AWK) '{split($$2,a,"."); print a[1]}')
PG_12_GE := $(shell [ $(PG_VERSION) -ge 12 ] && echo true)
PLPYTHONU := plpythonu
POSTGIS := postgis
ifeq ($(PG_12_GE), true)
PLPYTHONU := plpython3u
POSTGIS := postgis, postgis_raster
endif

REPLACEMENTS = -e 's/@@EXTVERSION@@/$(EXTVERSION)/g' -e 's/@@plpythonu@@/$(PLPYTHONU)/g' -e 's/@@postgis@@/$(POSTGIS)/g'
NEW_EXTENSION_ARTIFACT = $(EXTENSION)--$(EXTVERSION).sql

REGRESS = $(notdir $(basename $(sort $(wildcard test/sql/*test.sql))))
REGRESS_EXPEC = $(notdir $(basename $(sort $(wildcard test/expected/*test.out))))
TEST_DIR = test
REGRESS_OPTS = --inputdir='$(TEST_DIR)' --outputdir='$(TEST_DIR)' --user='postgres'

# DATA is a special variable used by postgres build infrastructure
# These are the files to be installed in the server shared dir,
# for installation from scratch, upgrades and downgrades.
# @see http://www.postgresql.org/docs/current/static/extend-pgxs.html
OLD_VERSIONS = $(wildcard old_versions/*.sql)
DATA = $(NEW_EXTENSION_ARTIFACT) \
		 $(EXTENSION)--*--*.sql \
		 $(OLD_VERSIONS)
SOURCES_DATA_DIR = sql/
SOURCES_DATA = $(wildcard sql/*.sql)


# postgres build stuff

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)


$(NEW_EXTENSION_ARTIFACT): $(SOURCES_DATA)
	rm -f $@
	cat $(SOURCES_DATA_DIR)/*.sql | \
		$(SED) -e $(REPLACEMENTS) >> $@
ifeq ($(PG_PARALLEL), 0)
# Remove PARALLEL in aggregates and functions
	$(eval TMPFILE := $(shell mktemp /tmp/$(basename $0).XXXXXXXX))
	$(SED) -e 's/PARALLEL \= [A-Z]*,/''/g' \
		-e 's/PARALLEL [A-Z]*/''/g' $@ > $(TMPFILE)
	mv $(TMPFILE) $@
endif

# $(EXTENSION).control: $(EXTENSION).control.in Makefile
# 	$(SED) $(REPLACEMENTS)  $< > $@

.PHONY: all
all: $(DATA)

.PHONY: $(EXTENSION).control
$(EXTENSION).control:
	$(SED) $(REPLACEMENTS) $(EXTENSION).control.in > $(EXTENSION).control

.PHONY: release
release: $(EXTENSION).control $(SOURCES_DATA)
	test -n "$(NEW_VERSION)"  # $$NEW_VERSION VARIABLE MISSING. Eg. make release NEW_VERSION=0.x.0
	git mv *.sql old_versions
	git add $(EXTENSION).control
	cat $(SOURCES_DATA_DIR)/*.sql > $(EXTENSION)--$(NEW_VERSION).sql
	$(ERB) version=$(NEW_VERSION) upgrade_downgrade_template.erb > $(EXTENSION)--$(EXTVERSION)--$(NEW_VERSION).sql
	$(ERB) version=$(EXTVERSION) upgrade_downgrade_template.erb > $(EXTENSION)--$(NEW_VERSION)--$(EXTVERSION).sql
	git add $(EXTENSION)--$(NEW_VERSION).sql
	@echo
	@echo "Please review the file $(EXTENSION)--$(EXTVERSION)--$(NEW_VERSION).sql.in and add any code needed to upgrade $(EXTVERSION) to $(NEW_VERSION)"
	@echo "Please review the file $(EXTENSION)--$(NEW_VERSION)--$(EXTVERSION).sql.in and add any code needed to downgrade $(NEW_VERSION) to $(EXTVERSION)"
	@echo

# Only meant for development time, do not use once a version is released
.PHONY: devclean
devclean:
	rm -f $(NEW_EXTENSION_ARTIFACT)

# If needed remove PARALLEL tags from the release files
.PHONY: release_replace_variables
release_replace_variables: $(EXTENSION).control
	for n in $(wildcard old_versions/*.sql *.sql); do \
		$(eval TMPFILE := $(shell mktemp /tmp/XXXXXXXXXX)) \
		if [ "$(PG_PARALLEL)" -eq "0" ]; then \
			$(SED) -e 's/PARALLEL \= [A-Z]*,/''/g' -e 's/PARALLEL [A-Z]*/''/g' $$n > $(TMPFILE); \
			mv $(TMPFILE) $$n; \
		fi; \
		$(SED) -e 's/@@plpythonu@@/$(PLPYTHONU)/g' $$n > $(TMPFILE); \
		mv $(TMPFILE) $$n; \
	done

# Install the current release into the PostgreSQL extensions directory
.PHONY: deploy
deploy: release_replace_variables
	$(INSTALL_DATA) $(EXTENSION).control '$(DESTDIR)$(datadir)/extension/'
	$(INSTALL_DATA) old_versions/*.sql *.sql '$(DESTDIR)$(datadir)/extension/'

.PHONY: install
install: deploy
