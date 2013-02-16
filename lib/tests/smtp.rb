require 'test'

module Testotron::Tests
	class SMTP < Testotron::Test
		KEY = "smtp"

		def initialize(host, port = 25)
			@host, @port = host, port
		end

		def human_name
			"SMTP test of #{@host}, port #{@port}"
		end

		def run(runner)
			runner.report self, "Testing SMTP server of #{@host} port #{@port}..."
			smtp = Net::SMTP.new(@host, @port)
			begin
				smtp.start
				smtp.finish
			rescue Errno::ECONNREFUSED => e
				raise TestFailed, "Server refused SMTP connection"
			rescue EOFError => e
				raise TestFailed, "EOF reached while connecting to SMTP server"
			rescue Exception
				raise TestFailed
			end
		end
	end
end
