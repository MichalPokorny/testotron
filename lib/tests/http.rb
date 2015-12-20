require 'test'

module Testotron
	module Tests
		class HTTP < Test
			KEY = "http"

			def initialize(host, options = {})
				@host = host
				@port = options[:port] || 80
				@requests = [*(options[:requests] || "http://#{host}")]
				@timeout = options[:timeout] || 2
				@grep = options[:grep]
				@retries = options[:retries] || 3
			end

			def human_name
				"HTTP test of #{@host}, port #{@port}, requests #{@requests.join ','}, #@retries retries"
			end

			private

			def get_response(http, page)
				begin
					uri = URI.parse(page).request_uri
					request = Net::HTTP::Get.new(uri)
					http.request(request)
				rescue Timeout::Error
					raise TestFailed, "HTTP connection timed out (Timeout::Error)"
				rescue Errno::ETIMEDOUT
					raise TestFailed, "HTTP connection timed out (ETIMEDOUT)"
				rescue Errno::ECONNREFUSED
					raise TestFailed, "HTTP connection refused (ECONNREFUSED)"
				rescue SocketError
					raise TestFailed, "HTTP connection failed (SocketError)"
				end
			end

			def response_code_good?(response)
				(100...400).include?(response.code.to_i)
			end

			def response_grep_matched?(response)
				!@grep || response.body.include?(@grep)
			end

			public

			def run(runner)
				runner.report self, "Testing HTTP server on #{@host} port #{@port}..."

				remaining_retries = @retries

				@requests.each do |page|
					runner.report self, "Trying #{page}..."

					http = Net::HTTP.new(@host, @port)
					http.read_timeout = @timeout
					http.open_timeout = @timeout

					begin
						response = get_response(http, page)

						unless response_code_good?(response)
							raise TestFailed, "Response code #{response.code} on #{@post}:#{@port} GET #{page}"
						end

						unless response_grep_matched?(response)
							raise TestFailed, "Response on GET #{page} doesn't match '#@grep'"
						end
					rescue TestFailed
						remaining_retries -= 1

						if remaining_retries > 0
							retry
						else
							raise
						end
					end
				end
			end
		end
	end
end
