#!/usr/bin/ruby

require 'mail'
require 'net/smtp'
require 'net/http'
require 'uri'

require 'tests/http'
require 'tests/smtp'

module Testotron
	class TestFailed < Exception
	end
	
	TEST_CLASSES = [ Tests::HTTP, Tests::SMTP ]

	class TestBuilder
		def initialize(runner)
			@runner = runner
			@report_methods = [ :local_mail ]
		end

		# TODO: save for later execution
		TEST_CLASSES.each { |klass|
			define_method klass.const_get(:KEY) do |*args|
				test = klass.new(*args)	
				begin
					test.run(@runner)
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
	class TestRunner
		def report(test, msg)
			puts test.class.to_s.rjust(20) + ": #{msg}"
		end

		REPORT_METHODS = [ :local_mail, :stderr, :xosdutil ]

		def report_error(methods, test, failure)
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
	end

	def self.test(*args)
		runner = TestRunner.new

		if block_given?
			yield(TestBuilder.new(runner))
		else
			raise ArgumentError if args.empty?
			test = args.shift.to_sym
			keys = TEST_CLASSES.map { |x| x.const_get(:KEY).to_sym }
			raise KeyError, "Unknown test: #{test}" unless TEST_CLASSES.map { |x| x.const_get(:KEY).to_sym }.include?(test)
			TEST_CLASSES.each { |klass|
				if klass.const_get(:KEY).to_sym == test
					klass.new(*args).run(runner)
					break
				end
			}
		end
	end
end
