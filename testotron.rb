#!/usr/bin/ruby

require 'mail'
require 'net/smtp'
require 'net/http'
require 'uri'

class TestFailed < Exception
end

class Test
	def report(msg)
		puts self.class.to_s.rjust(20) + ": #{msg}"
	end
end

class SMTPTest < Test
	KEY = "smtp"

	def initialize(host, port = 25)
		@host, @port = host, port
	end

	def human_name
		"SMTP test of #{@host}, port #{@port}"
	end

	def run
		report "Testing SMTP server of #{@host} port #{@port}..."
		smtp = Net::SMTP.new(@host, @port)
		begin
			smtp.start
			smtp.finish
		rescue Errno::ECONNREFUSED => e
			raise TestFailed, "Server refused SMTP connection"
		rescue EOFError => e
			raise TestFailed, "EOF reached while connecting to SMTP server"
		rescue Exception => e
			raise TestFailed, e
		end
	end
end

class HTTPTest < Test
	KEY = "http"

	def initialize(host, port = 80, requests = nil)
		if requests.nil?
			requests = "http://#{host}/"
		end
		@host, @port, @requests = host, port, [*requests]
	end

	def human_name
		"HTTP test of #{@host}, port #{@port}, requests #{@requests.join ','}"
	end

	def run
		report "Testing HTTP server on #{@host} port #{@port}..."
		http = Net::HTTP.new(@host, @port)
		@requests.each do |page|
			report "Trying #{page}..."
			request = Net::HTTP::Get.new URI.parse(page).request_uri
			response = http.request(request)

			if response.code.to_i != 200
				raise TestFailed, "Response not 200 on #{@post}:#{@port} GET #{page}"
			end
		end
	end
end

class Testotron
	REPORT_METHODS = [ :local_mail, :stderr, :xosdutil ]

	class TestBuilder
		def initialize(runner)
			@runner = runner
			@report_methods = [ :local_mail ]
		end

		TEST_CLASSES = [ SMTPTest, HTTPTest ]

		# TODO: save for later execution
		TEST_CLASSES.each { |klass|
			define_method klass.const_get(:KEY) do |*args|
				test = klass.new(*args)	
				begin
					test.run
				rescue TestFailed => failure
					@runner.report_error(@report_methods, test, failure)
				end
			end
		}

		def report_with(*methods)
			@report_methods = methods.map &:to_sym
		end
	end

	# TODO: set mail target

	def self.report_error(methods, test, failure)
		if methods.include?(:local_mail)
			mail = Mail.new do
				from 'conftest@localhost'
				to `whoami`.chomp
				subject "Configuration test failed!"
				body <<EOF
	Test:
		#{test.human_name}

	Message: 
		#{failure.message}
EOF
			end

			mail.delivery_method :sendmail
			mail.deliver
		end

		if methods.include? :xosdutil
			system "xosdutilctl", "echo", "Configuration test (#{test.human_name}) failed!"
		end

		if methods.include? :stderr
			STDERR.puts "Test failed: #{test.human_name} (message: #{failure.message})"
		end
	end

	def self.test
		yield(TestBuilder.new(self))
	end
end
