#
# Build mock and local RPM versions of tools for RT
#

# Assure that sorting is case sensitive
LANG=C

# Ignore ownership and group,
RSYNCOPTS=-a --no-owner --no-group
# Skip existing files to avoid binary churn in yum repos
RSYNCSAFEOPTS=$(RSYNCOPTS) --ignore-existing 

# "mock" configurations to build with, activate only as needed
#MOCKS+=epel-6-i386
#MOCKS+=epel-5-i386
MOCKS+=epel-6-x86_64
#MOCKS+=epel-5-x86_64

SPEC = `ls *.spec`

# Local yum compatible RPM repository
REPOBASEDIR="`/bin/pwd | xargs dirname`/rt4repo"

all:: $(MOCKS)

srpm:: FORCE
	@echo Building *.spec SRPM
	rm -rf rpmbuild
	rpmbuild \
		--define '_topdir $(PWD)/rpmbuild' \
		--define '_sourcedir $(PWD)' \
		-bs $(SPEC) --nodeps

build:: srpm FORCE
	rpmbuild \
		--define "_topdir $(PWD)/rpmbuild" \
		--rebuild rpmbuild/SRPMS/*.src.rpm

$(MOCKS):: FORCE
	@if [ -n "`find $@ -name \*.rpm ! -name \*.src.rpm 2>/dev/null`" ]; then \
		echo "	Skipping $(SPEC) in $@ with RPMS"; \
	else \
		echo "	Building $(SPEC) SRPM in $@"; \
		rm -rf $@; \
		/usr/bin/mock -q -r $@ --sources=$(PWD) \
		    --resultdir=$(PWD)/$@ \
		    --buildsrpm --spec=$(SPEC); \
		echo "Storing " $@/*.src.rpm "as $@.src.rpm"; \
		/bin/mv $@/*.src.rpm $@.src.rpm; \
		echo "Building $@.src.rpm in $@"; \
		rm -rf $@; \
		/usr/bin/mock -q -r $@ \
		     --resultdir=$(PWD)/$@ \
		     $@.src.rpm; \
	fi

mock:: $(MOCKS)

install:: $(MOCKS)
	@echo $@ not enabled

clean::
	rm -rf $(MOCKS)
	rm -rf rpmbuild

realclean distclean:: clean
	rm -f *.src.rpm

FORCE:
