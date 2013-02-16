#!/usr/bin/ruby

# Example Testotron script

# Load Testotron
require './testotron.rb'

ConfTest.new.test do |t|
	# Test several pages on an alternate HTTP port
	t.http "example.org", "80", [ "http://example.org", "http://something.example.org/else.html" ]

	# Test default HTTP port
	t.http "example.org"

	# Test some nondefault page
	t.http "example.org", "80", "http://example.org/hello/world.html"

	# Test a SMTP server, with an optional alternate port
	t.smtp "example.org"
	t.smtp "example.org", 3315
end


