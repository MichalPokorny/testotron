Testotron
=========

I need to automatically test my servers and I didn't quite find what I needed
anywhere.

Testotron can detect basic errors in your configuration, like a server not starting
or a blocked port.

Testotron on RubyGems: https://rubygems.org/gems/testotron.

Installation
------------

Just run `gem install testotron` or add `testotron` to your Gemfile, and you should be good.

Usage example
-------------

	#!/usr/bin/ruby
	# Load Testotron
	require 'testotron'

	Testotron.test do |t|
		# First set report modes.
		t.report_with :local_mail, :stderr, :xosdutil

		# Test several pages on an alternate HTTP port
		t.http "example.org", port: 8080, requests: ["http://example.org", "http://something.example.org/else.html"]

		# Test default HTTP port
		t.http "example.org"

		# Test default HTTP port, retry 10 times instead of the default 3 times
		t.http "example.org", retries: 10

		# Test default HTTP port with timeout of 10 seconds (2 secs is default)
		t.http "example.org", timeout: 10

		# You can ask the tests to run quietly (without messages on STDOUT)
		t.quiet = true # or t.quiet!

		puts "OK so far." if t.ok?
		puts "Errors in previous tests." if t.errors?

		# Test some nondefault page
		t.http "example.org", port: 80, requests: "http://example.org/hello/world.html"

		# Test that some text is present in the response.
		t.http "example.org", grep: "hello"

		# Test a SMTP server, with an optional alternate port
		t.smtp "example.org"
		t.smtp "example.org", 3315
	end

	# Run a single test.
	# Single tests are quiet by default
	Testotron.test :smtp, "example.org", 3315

Supported report modes
----------------------

* `local_mail`: Mails you a simple e-mail to `(your username)@localhost`.
* `stderr`: Writes a one-line error message to STDERR.
* `xosdutil`: Runs `xosdutil echo (error message)`. I'm sorry if you don't happen
  to be amongst the numerous ranks of xosdutil users :)
