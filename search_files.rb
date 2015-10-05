require 'pry'
require 'json'

team_name = ARGV[0]
file_path = ARGV[1]
items = JSON.parse(File.read(file_path))

image_prefixes = %w(https://qiita-image-store.s3.amazonaws.com https://#{team_name}.qiita.com/files)
files = []

items['articles'].sort_by{ |item| item['updated_at'] }.each.with_index do |item, index|
  image_prefixes.each do |image_prefix|
    if matches = item['body'].match(/(#{image_prefix}\/[^\s)]+)/)
      files << matches[0]
    end
  end
end

puts files
