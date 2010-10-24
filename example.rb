require 'wordpress_import'

content = ""
open("sample_wordpress.xml") do |s| content = s.read end

WordPress.parse(content) do | article |
  puts "----"
  puts "Title: " + article.title
  puts article.body
  puts
  puts "Comments:"
  article.comments.each do |comment|
    puts "  Author: " + comment.author
    puts "  " + comment.content
    puts
  end
  puts "Tags: " + article.tags.join(", ")

end
