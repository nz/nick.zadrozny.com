#!/usr/bin/env ruby

require 'fileutils'
require 'open-uri'
require 'yajl'
require 'nokogiri'
require 'jekyll'
require 'digest/md5'

class TumblrImport
  
  attr_accessor :api_url
  attr_accessor :per_page
  attr_accessor :current_page
  attr_accessor :tumblr_posts
  attr_accessor :jekyll_posts
  attr_accessor :posts_path
  
  def initialize(url, dest)
    @api_url      = "#{url.gsub(/\/$/,'')}/api/read/json/"
    @per_page     = 50
    @tumblr_posts = []
    @jekyll_posts = []
    @current_page = 0
    @posts_path   = File.expand_path("#{dest}/_posts", File.dirname(__FILE__))
    FileUtils.mkdir_p("tmp/tumblr/cache")
    FileUtils.mkdir_p("tmp/tumblr/files")
    FileUtils.mkdir_p(@posts_path)
  end
  
  def run!
    current_page = 0
    begin
      current_page = current_page + 1
      puts "Processing page #{current_page}..."
      json = cached_open("#{api_url}?num=#{per_page}&start=#{current_page * per_page}")
      blog = Yajl::Parser.parse(json)
      blog['posts'].each do |post|
        write_post(post_to_jekyll_hash(post))
      end
    end until blog['posts'].size < per_page
  end
  
  # Given a Jekyll-formatted post hash, write it out to disk
  def write_post(post)
    # output path and content
    path    = "#{posts_path}/#{post[:name]}"
    content = post[:header].to_yaml + "---\n" + post[:content]
    
    # short-circuit to skip a file that hasn't changed
    contents_match = if FileTest.exists?(path)
      if Digest::MD5.digest(content.strip) == Digest::MD5.digest(File.open(path).read.strip)
        true
      end
    end
    
    # write out the post
    unless contents_match
      begin
        File.open(path, "w") do |f|
          f.puts(content)
        end
      rescue Errno::ENAMETOOLONG => e
        puts "Filename too long, checking the original on Tumblr"
        system "open #{post[:url]}"
      end
    end
  end
  
  def create_slug(str)
    pieces = str.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '').split(/-/)
    i = 0
    while pieces[0, i+1].join('-').length < 50 && i < pieces.length
      i += 1
    end
    pieces[0, i].join('-')
  end
  
  def post_to_jekyll_hash(post)
    title = ""
    content = ""
    case post['type']
    when "regular"
      title = post["regular-title"]
      content = post["regular-body"]
    when "link"
      title = post["link-text"] || post["link-url"]
      content = "<h3><a href=\"#{post["link-url"]}\">#{title}</a></h3>"
      unless post["link-description"].nil?
        content << "\n" + post["link-description"]
      end
    when "photo"
      title = post["photo-caption"]
      max_size = post.keys.map{ |k| k.gsub("photo-url-", "").to_i }.max
      url = post["photo-url"] || post["photo-url-#{max_size}"]
      ext = "." + post[post.keys.select { |k|
        k =~ /^photo-url-/ && post[k].split("/").last =~ /\./
      }.first].split(".").last
      content = "<img src=\"#{save_file(url, ext)}\"/>"
      unless post["photo-link-url"].nil?
        content = "<a href=\"#{post["photo-link-url"]}\">#{content}</a>"
      end
    when "audio"
      if !post["id3-title"].nil?
        title = post["id3-title"]
        content = post.at["audio-player"] + "<br/>" + post["audio-caption"]
      else
        title = post["audio-caption"]
        content = post.at["audio-player"]
      end
    when "quote"
      title = post["quote-text"]
      content = "<blockquote>#{post["quote-text"]}</blockquote>"
      unless post["quote-source"].nil?
        content << "&#8212;" + post["quote-source"]
      end
    when "conversation"
      title = post["conversation-title"]
      content = "<section><dialog>"
      post["conversation"].each do |line|
        content << "<dt>#{line['label']}</dt><dd>#{line}</dd>"
      end
      content << "</section></dialog>"
    when "video"
      title = post["video-title"]
      content = post["video-player"]
      unless post["video-caption"].nil?
        content << "<br/>" + post["video-caption"]
      end
    else
      puts "Unknown post type: #{post['type']}"
    end
    
    date  = Date.parse(post['date']).to_s
    title = Nokogiri::HTML(title).text
    slug  = create_slug(title)
    {
      :name => slug.length > 0 ? "#{date}-#{slug}.html" : "#{date}.html",
      :header => {
        'layout' => 'post',
        'title'  => title,
        'tags'   => post['tags'],
        'type'   => post['type']
      },
      :content => content,
      :url =>  post['url'],
      :slug => post['url-with-slug'],
    }
  end
  
  protected
  
  def cached_open(url)
    cachefile_path = "tmp/tumblr/cache/" + url.gsub(/[^a-z0-9]/,'-').gsub(/-+/,'-')
    if FileTest.exists?(cachefile_path)
      open(cachefile_path).readlines.join("\n")[/\{.*\}/]
    else
      content = open(url)
      content = content.readlines.join("\n")
      cachefile = File.open(cachefile_path, 'w')
      cachefile.write(content)
      cachefile.close
      content[/\{.*\}/]
    end
  end
  
  def save_file(url, ext)
    path = "tmp/tumblr/files/#{url.split('/').last}"
    path += ext unless path =~ /#{ext}$/
    unless FileTest.exists?(path)
      puts "Saving file: #{url}..."
      File.open(path, "w") { |f| f.write(open(url).read) }
      url = "/" + path
    end
  end
  
end

TumblrImport.new("http://nick.zadrozny.com/", "site").run!
