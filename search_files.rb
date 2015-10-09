require 'pry'
require 'json'

team_name = ARGV[0]
file_path = ARGV[1]
items = JSON.parse(File.read(file_path))

image_prefixes = %W(https://qiita-image-store.s3.amazonaws.com https://#{team_name}.qiita.com/files)

files = []
items['articles'].sort_by{ |item| item['updated_at'] }.each.with_index do |item, index|
  image_prefixes.each do |image_prefix|
    if matches = item['body'].scan(/(#{image_prefix}\/[^\s)]+)/)
      matches.each do |match|
        files << match[0]
      end
    end
  end
end

puts files
