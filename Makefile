RAILS_ENV = test
BUNDLE = RAILS_ENV=${RAILS_ENV} bundle
BUNDLE_OPTIONS = -j 3
RSPEC = rspec
APPRAISAL = appraisal

test: bundler appraisal
	${BUNDLE} exec ${APPRAISAL} ${RSPEC} spec 2>&1

bundler:
	if ! gem list bundler -i > /dev/null; then \
	  gem install bundler --no-ri --no-rdoc; \
	fi
	${BUNDLE} install ${BUNDLE_OPTIONS}

appraisal:
	${BUNDLE} exec ${APPRAISAL} install