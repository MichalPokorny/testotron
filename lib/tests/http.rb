require 'test'

module Testotron::Tests
	class HTTP < Testotron::Test
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

		def run(runner)
			runner.report self, "Testing HTTP server on #{@host} port #{@port}..."
			http = Net::HTTP.new(@host, @port)
			@requests.each do |page|
				runner.report self, "Trying #{page}..."
				request = Net::HTTP::Get.new URI.parse(page).request_uri

				begin
					response = http.request(request)
				rescue Errno::ETIMEDOUT
					raise TestFailed, "HTTP connection timed out"
				rescue Errno::ECONNREFUSED
					raise TestFailed, "HTTP connection refused"
				end

				if response.code.to_i != 200
					raise TestFailed, "Response not 200 on #{@post}:#{@port} GET #{page}"
				end
			end
		end
	end
end
