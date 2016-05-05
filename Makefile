test:
	RUBYLIB=./lib cutest test/**/*_test.rb

build:	quickblox-rb.gemspec
	gem build $?

clean:
	rm *.gem

.PHONY: test
