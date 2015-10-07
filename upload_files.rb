require 'esa'
require 'json'
require 'pry'

access_token = ARGV[0]
team_name = ARGV[1]
file_path = ARGV[2]
qiita_team_cookie = ARGV[3]

client = Esa::Client.new(
  access_token: access_token,
  current_team: team_name, # 移行先のチーム名(サブドメイン)
)

class ImageUploader
  attr_accessor :client, :files, :qiita_team_cookie

  def initialize(client, file_path, qiita_team_cookie)
    @client = client
    @files  = File.read(file_path).split("\n")
    @qiita_team_cookie = qiita_team_cookie
  end

  def upload!
    files.each.with_index do |file, index|
      response_body = wrap_response { client.upload_attachment([file, qiita_team_cookie]) }
      esa_url = response_body['attachment']['url']

      puts "#{file} #{esa_url}"
    end
  end

  def wrap_response(&block)
    response = block.call

    case response.status
    when 200
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

  def wait_for(seconds)
    (seconds / 10).times do
      print '.'
      sleep 10
    end
    puts
  end
end

uploader = ImageUploader.new(client, file_path, qiita_team_cookie)
uploader.upload!
