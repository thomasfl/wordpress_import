# -*- coding: utf-8 -*-
require 'rubygems'
require 'nokogiri'
require 'time'

# Parse WordPress xml interchange file format (wxr)

class WordPressComment
  attr_accessor :id, :author, :author_email, :author_url, :author_IP, :date, :date_gmt, :content, :approved, :type, :parent, :user_id, :article_url

  def initialize(options={})
    options.each{|k,v|send("#{k}=",v)}
  end

end

class WordPress

  #Hold articles
  class Article

    attr_accessor :title, :body, :owner, :status, :url, :filename, :publishedDate, :date, :year, :month, :tags, :picture, :comments

    def initialize(options={})
      options.each{|k,v|send("#{k}=",v)}
    end

    def to_s
      "#<WordPressArticle "+instance_variables.collect{|var|var+": "+instance_variable_get(var).to_s}.join(",")+">"
    end

  end

  # Removed garbage created by MS Word.
  def self.removeWordGarbage(html)
    # start by completely removing all unwanted tags
    html = html.gsub(/<[\/]?(font|span|xml|del|ins|[ovwxp]:\w+)[^>]*?>/i, '')
    # then remove unwanted attributes
    html = html.gsub(/ (class|style)="[^"]*"/i,"")
    html = html.gsub("<strong><strong>", "<strong>")
    html = html.gsub("<strong><strong>", "<strong>")
    html = html.gsub("</strong></strong>", "</strong>")
    html = html.gsub("</strong></strong>", "</strong>")
    html = html.gsub("<strong></strong>", "")
    return html
  end

  def self.addParagraphs(body)
    response = ""
    body.split(/\n/).each do |line|
      if(line != "")
        response += "<p>" + line + "</p>\n"
      end
    end
    return response
  end

  # Parse wordpress xml data, yields Article objects
  def self.parse(content, &block)
    doc = Nokogiri::XML(content)
    puts "Debug: parse item"
    doc.xpath('//item').each do |article|

      title = article.at('title').content

      body = article.xpath('content:encoded').first.content.to_s

      # body = body.gsub(/^(<img.*>)$/i,'')   # Remove first img tag
      body = body.gsub(/^(<img [^>]*>)/i,'')  # Remove first img tag
      picture = nil
      if($1)
        img = $1
        picture = img[/src=\"([^\"]*)\"/i,1] # ...and store img url
        picture = picture.sub(/\?.*$/,'')
      end

      if(picture == nil and body =~ /<a href[^>]*><img .*src[^"]"([^"]*).*<\/a>/i)
        picture = $1
        body = body.sub(/<a href[^>]*><img .*src[^"]"([^"]*).*<\/a>/i,'')
      end

      body = removeWordGarbage(body)
      body = addParagraphs(body)

      owner = article.xpath('dc:creator', 'dc' => "http://purl.org/dc/elements/1.1/").first.content.to_s + "@uio.no"
      status = article.xpath('wp:status').first.content.to_s
      url =  article.at('link').content
      filename = url[/\/([^\/]*)\/$/,0].to_s.gsub("/","")
      publishedDate = article.at('pubDate').content
      date = Time.parse(publishedDate)
      year = date.year.to_s
      month = date.month.to_s
      if(month.to_i < 10)
        month = "0" + month.to_i.to_s
      end

      tags = []
      article.xpath('category').each do |category|
        if(category['domain'] and category['domain'] == 'category' )
          tags << category.content
        end
      end

      comments = []
      article.xpath('wp:comment').each do |comment|
        if(comment.xpath('wp:comment_approved').text == "1")then
          comment = WordPressComment.new(:author => comment.xpath('wp:comment_author').text,
                                         :author_email =>  comment.xpath('wp:comment_author_email').text,
                                         :content => comment.xpath('wp:comment_content').text,
                                         :date => comment.xpath('wp:comment_date').text,
                                         :date_gmt => comment.xpath('wp:comment_date_gmt').text,
                                         :author_url => comment.xpath('wp:comment_author_url').text,
                                         :author_IP => comment.xpath('wp:comment_author_IP').text )
          comments << comment
        end
      end

      if(status == "publish")
        wp_article = WordPress::Article.new(:title => title,
                                            :body => body,
                                            :owner => owner,
                                            :status => status,
                                            :url => url,
                                            :filename => filename,
                                            :publishedDate => publishedDate,
                                            :date => date,
                                            :year => year,
                                            :month => month,
                                            :tags => tags,
                                            :picture => picture,
                                            :comments => comments)
        yield wp_article
      end

    end

  end

end
