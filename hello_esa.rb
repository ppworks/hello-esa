require 'esa'
require 'json'
require 'pp'
require 'pry'

class Importer
  def initialize(client, file_path)
    @client = client
    @items  = JSON.parse(File.read(file_path))
  end
  attr_accessor :client, :items

  def wait_for(seconds)
    (seconds / 10).times do
      print '.'
      sleep 10
    end
    puts
  end

  def import(dry_run: true, start_index: 0)
    users_map = {
    }

    items['articles'].sort_by{ |item| item['updated_at'] }.each.with_index do |item, index|
      next unless index >= start_index
      break if 0 < index

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
        user:     users_map[item['user']['id']] || 'esa_bot',  # 記事作成者上書き: owner権限が必要
      }

      if dry_run
        puts "***** index: #{index} *****"
        pp params
        puts
        next
      end

      print "[#{Time.now}] index[#{index}] #{item['title']} => "
      response = client.create_post(params)
      case response.status
      when 201
        puts "created: #{response.body["full_name"]}"

        item['comments'].each do |comment|
          comment_params = {
            body_md:  <<-BODY_MD,
Original created at:#{comment['created_at']}
Qiita:Team:User:#{comment['user']['id']}

#{comment['body']}
BODY_MD
            user:     users_map[comment['user']['id']] || 'esa_bot'
          }
          comment_response = client.create_comment(response.body['number'], comment_params)

          case comment_response.status
          when 201
            puts "created comment"
          when 429
            retry_after = (comment_response.headers['Retry-After'] || 20 * 60).to_i
            puts "rate limit exceeded: will retry after #{retry_after} seconds."
            wait_for(retry_after)
            redo
          else
            puts "failure with status: #{comment_response.status}"
            exit 1
          end
        end
      when 429
        retry_after = (response.headers['Retry-After'] || 20 * 60).to_i
        puts "rate limit exceeded: will retry after #{retry_after} seconds."
        wait_for(retry_after)
        redo
      else
        puts "failure with status: #{response.status}"
        exit 1
      end
    end
  end
end

client = Esa::Client.new(
  access_token: ARGV[1],
  current_team: ARGV[0], # 移行先のチーム名(サブドメイン)
)
importer = Importer.new(client, './qiita-team.json')

# dry_run: trueで確認後に dry_run: falseで実際にimportを実行
importer.import(dry_run: false, start_index: 0)
