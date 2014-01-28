#!/usr/bin/ruby

# Example Testotron script

# Load Testotron
require 'testotron.rb'

Testotron.test do |t|
	# Test several pages on an alternate HTTP port
	t.http "example.org", port: 8080, requests: ["http://example.org", "http://something.example.org/else.html"]

	# Test default HTTP port
	t.http "example.org"

	# Test some nondefault page
	t.http "example.org", requests: "http://example.org/hello/world.html"

	# Test some nondefault page with a timeout of 10 seconds
	t.http "example.org", requests: "http://example.org/hello/world.html", timeout: 10

	# Test some nondefault page and grep it for something
	t.http "example.org", requests: "http://example.org/hello/world.html", grep: "I should contain this string."

	# Test a SMTP server, with an optional alternate port
	t.smtp "example.org"
	t.smtp "example.org", 3315
end


