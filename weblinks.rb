# coding: utf-8
require 'mechanize'
require 'logger'

class Weblinks
  attr_reader :agent, :url, :before_link, :already_linked, :wrong_url, :exclusion_link
  
  access_log_path = "#{File.dirname(__FILE__)}/log"
  FileUtils.mkdir(access_log_path) unless FileTest.exists?(access_log_path)
  Mechanize.log = Logger.new("#{access_log_path}/access_#{Time.now.to_i}.log")
  
  def initialize(options={})
    opts = {url: nil, user_agent: 'Windows Mozilla', wrong_url: [], exclusion_link: [], auth: nil}.merge(options)
    
    @url = opts[:url]
    @before_link = nil
    @already_linked = []
    @wrong_url = opts[:wrong_url]
    @exclusion_link = opts[:exclusion_link]
    @app_logs = []
    @app_error_logs = []
    
    @agent = Mechanize.new
    @agent.user_agent_alias = opts[:user_agent]
    @agent.follow_meta_refresh = true
    @agent.get(@url)
  end
  
  def dump
    execute
    
    dump_log
  end
  
  def to_a
    execute
    
    @app_logs + @app_error_logs
  end
  
  def errors
    return @app_error_logs unless @app_error_logs.empty?
    
    execute
    @app_error_logs
  end
  
  private
    def execute
      @agent.page.links.each do |link|
        next if exclusion_link? link
        next if already_linked? link
        next if wrong_url? link
        
        begin
          @before_link = link.uri
          @already_linked << @before_link
          link.click
          dump_link
          if white_link_count(@agent.page.links) == 0
            @agent.get @before_link
          else
            execute
          end
        rescue => e
          @app_error_logs << {url: link.uri.to_s, title: link, message: e}
        end
      end
      
      @app_logs       = @app_logs.uniq
      @app_error_logs = @app_error_logs.uniq
    end
  
    def outer_url?(link)
      link.uri.to_s[/^http/] && link.uri.to_s[/^#{@url}/].nil?
    end
    
    def wrong_url?(link)
      @wrong_url.include?(link.uri) || outer_url?(link)
    end
    
    def already_linked?(link)
      @already_linked.include? link.uri
    end
    
    def exclusion_link?(link)
      exclusion_link.include? link.uri
    end
    
    def dump_link
      @app_logs << {url: @agent.page.uri, title: @agent.page.title}
    end
    
    def white_link_count(links)
      count = 0
      links.each do |link|
        count += 1 unless already_linked?(link) && exclusion_link?(link)
      end
      count
    end
  
    def dump_log
      open(File.dirname(__FILE__) + "/log/#{File.basename(__FILE__, '.rb')}.log", 'w') do |file|
        @app_logs.each do |log|
          file.puts "#{log[:url]}: #{log[:title]}"
        end
      end
      
      open(File.dirname(__FILE__) + "/log/#{File.basename(__FILE__, '.rb')}_error.log", 'w') do |file|
        @app_error_logs.each do |log|
          file.puts "#{log[:url]}: #{log[:title]}: #{log[:message]}"
        end
      end
    end
end