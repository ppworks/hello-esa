module Retryable
  def wait_for(seconds)
    (seconds / 10).times do
      print '.'
      sleep 10
    end
    puts
  end

  def wrap_response(&block)
    response = block.call

    case response.status
    when 200, 201
      response.body
    when 429
      retry_after = (response.headers['Retry-After'] || 20 * 60).to_i
      puts "rate limit exceeded: will retry after #{retry_after} seconds."
      wait_for(retry_after)
      # retry
      wrap_response &block
    else
      puts "failure with status: #{response.status}"
      exit 1
    end
  end
end
