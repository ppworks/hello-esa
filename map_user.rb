require 'esa'
require 'pry'

access_token = ARGV[0]
team_name = ARGV[1]
qiita_team_user = ARGV[2]
esa_user = ARGV[3]

client = Esa::Client.new(
  access_token: access_token,
  current_team: team_name, # 移行先のチーム名(サブドメイン)
)

class UserConverter
  CONVERT_KEY_PREFIX = ARGV[4] || "Qiita:Team:User:"

  def initialize(client, qiita_team_user, esa_user)
    @client = client
    @qiita_team_user = qiita_team_user
    @esa_user = esa_user
  end

  def convert!
    # posts
    posts = all_posts('body')
    posts.each do |post|
      puts wrap_response { @client.update_post(post['number'], created_by: @esa_user)}['full_name']
    end

    # comments
    posts = all_posts('comment')
    posts.each do |post|
      comments = all_comments(post['number'])

      comments.each do |comment|
        next unless comment['body_md'].match @qiita_team_user

        puts 'update comment'
        wrap_response {
          @client.update_comment(comment['id'], user: @esa_user)
        }
      end
    end
  end

  def all_posts(search_type)
    collection = Collection.new

    loop do
      response_body = wrap_response {
        @client.posts(page: collection.page,
                      per_page: collection.per,
                      q: "#{search_type}:#{CONVERT_KEY_PREFIX}#{@qiita_team_user}")
      }
      collection.data += response_body['posts']
      break unless response_body['next_page']

      collection.page = response_body['next_page']
    end

    collection.data
  end

  def all_comments(post_number)
    collection = Collection.new

    loop do
      response_body = wrap_response {
        @client.comments(post_number,
                         page: collection.page,
                         per_page: collection.per)
      }
      collection.data += response_body['comments']
      break unless response_body['next_page']

      collection.page = response_body['next_page']
    end

    collection.data
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

class Collection
  attr_accessor :data, :page, :per

  def initialize
    @data = []
    @page = 1
    @per  = 100
  end
end

user_converter = UserConverter.new(client, qiita_team_user, esa_user)
user_converter.convert!
