require 'esa'
require 'json'
require 'pry'
require './lib/retryable'

access_token = ARGV[0]
team_name = ARGV[1]
file_path = ARGV[2]
qiita_team_cookie = ARGV[3]

client = Esa::Client.new(
  access_token: access_token,
  current_team: team_name, # 移行先のチーム名(サブドメイン)
)

class ImageUploader
  include Retryable
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
end

uploader = ImageUploader.new(client, file_path, qiita_team_cookie)
uploader.upload!
