# bundle exec ruby ./hello_esa.rb access_token team_name ./qiita-team.json

require 'esa'
require 'json'
require 'pp'
require 'pry'

access_token = ARGV[0]
team_name = ARGV[1]
file_path = ARGV[2]

client = Esa::Client.new(
  access_token: access_token,
  current_team: team_name, # 移行先のチーム名(サブドメイン)
)

class Importer
  attr_accessor :client, :items

  def initialize(client, file_path)
    @client = client
    @items  = JSON.parse(File.read(file_path))
  end

  def import!(dry_run: true, start_index: 0)
    items['articles'].sort_by{ |item| item['updated_at'] }.each.with_index do |item, index|
      next unless index >= start_index
      next if 0 < index # debug

      params = {
        name:     item['title'],
        category: "Imports/Qiita",
        tags:     item['tags'].map{ |tag| tag['name'].gsub('/', '-') },
        body_md:  <<-BODY_MD,
Original created at:#{item['created_at']}
Qiita:Team:User:#{item['user']['id']}

#{item['body']}
BODY_MD
        wip:      false,
        message:  '[skip notice] Imported from Qiita',
        user:     'esa_bot',  # 記事作成者上書き: owner権限が必要
      }

      if dry_run
        puts "***** index: #{index} *****"
        pp params
        puts
        next
      end

      print "[#{Time.now}] index[#{index}] #{item['title']} => "

      response_body = wrap_response { client.create_post(params) }

      item['comments'].each do |comment|
        comment_params = {
          body_md:  <<-BODY_MD,
#{comment['body']}

<div style="color: #ccc">Original created at:#{comment['created_at']}</div>
<div style="color: #ccc">Qiita:Team:User:#{comment['user']['id']}</div>
BODY_MD
          user: 'esa_bot'
        }
        wrap_response { client.create_comment(response_body['number'], comment_params) }
      end
    end
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

  def wait_for(seconds)
    (seconds / 10).times do
      print '.'
      sleep 10
    end
    puts
  end
end

class Collection
  attr_accessor :data, :page, :per

  def initialize
    @data = []
    @page = 1
    @per  = 100
  end
end

importer = Importer.new(client, file_path)
# dry_run: trueで確認後に dry_run: falseで実際にimportを実行
importer.import!(dry_run: false, start_index: 0)
