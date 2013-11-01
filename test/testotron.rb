require 'test/unit'
require 'testotron'

class TestotronTest < Test::Unit::TestCase
	GOOD_HTTP_SERVER = "google.com"
	GOOD_SMTP_SERVER = "smtp.google.com"

	def test_single_http_on_good_server
		Testotron.test :http, "example.org", port: 80, requests: "http://www.example.org/"
	end

	def test_single_smtp_on_good_server
		Testotron.test :smtp, GOOD_SMTP_SERVER
	end

	def test_successful_test_battery
		tests_ok = nil
		test_errors = nil
		Testotron.test do |t|
			t.quiet = true
			t.report_with [] # No reports
			t.http "google.com", port: 80, requests: "http://www.google.com/", grep: "body"
			t.smtp GOOD_SMTP_SERVER
			tests_ok = t.ok?
			test_errors = t.errors?
		end

		assert !test_errors
		assert tests_ok
	end

	def test_failing_test_battery
		complaints = []
		tests_ok = nil
		test_errors = nil
		Testotron.test do |t|
			t.quiet = true
			t.report_with [] # No reports
			t.complain_using { |test, error|
				complaints << [test, error]
			}
			t.smtp "www.example.org"
			tests_ok = t.ok?
			test_errors = t.errors?
		end

		assert !tests_ok
		assert test_errors

		assert(complaints.length == 1)

		test, error = complaints.first
		assert(test.is_a? Testotron::Test)
		assert(error.is_a? Testotron::TestFailed)
	end
end
