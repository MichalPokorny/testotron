#!/usr/bin/ruby

require 'mail'
require 'net/smtp'
require 'net/http'
require 'uri'

require 'tests/http'
require 'tests/smtp'

module Testotron
	TEST_CLASSES = [ Tests::HTTP, Tests::SMTP ]

	class TestBuilder
		def initialize(runner)
			@errors = false
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
					complain(test, failure)
				end
			end
		}

		def ok?
			!@errors
		end

		def errors?
			@errors
		end

		def complain(test, failure)
			@errors = true
			if @complaint_block
				@complaint_block.call(test, failure)
			end
			@runner.report_error(@report_methods, test, failure)
		end

		def report_with(*methods)
			methods = methods.first if methods.length == 1
			methods = [methods] unless methods.is_a? Array
			@report_methods = methods.map &:to_sym
		end

		def complain_using(&block)
			raise ArgumentError, "No block given to complain to" unless block
			@complaint_block = block
		end

		def quiet
			@runner.quiet
		end

		def quiet=(value)
			@runner.quiet = value
		end

		def quiet!
			quiet = true
		end
	end

	# TODO: set mail target
	class TestRunner
		def report(test, msg)
			unless @quiet
				puts test.class.to_s.rjust(20) + ": #{msg}"
			end
		end

		attr_accessor :quiet

		def initialize
			@quiet = false
		end

		VALID_REPORT_METHODS = [ :local_mail, :stderr, :xosdutil ]

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
		runner.quiet = true

		if block_given?
			return yield(TestBuilder.new(runner))
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
