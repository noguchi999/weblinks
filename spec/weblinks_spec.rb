# coding: utf-8
require 'rspec'
require File.expand_path("weblinks")

describe Weblinks, "instance when it " do
  before do
    opts = {url: 'http://ec2-46-51-232-200.ap-northeast-1.compute.amazonaws.com/2013/madorin/'}
    @weblinks = Weblinks.new(opts)
  end
  
  it "method dump should create files name of weblinks.log and weblinks_error.log in ./log/ ." do
    app_log = File.expand_path("log/weblinks.log")
    app_error_log = File.expand_path("log/weblinks_error.log")
    begin
      FileUtils.rm([app_log, app_error_log])
    rescue => e
      puts e
    end
  
    @weblinks.dump
    
    (FileTest.exist?(app_log) && FileTest.exist?(app_error_log)).should be_true
  end
  
  it "method to_a should return Array size 43" do
    results = @weblinks.to_a
    
    results.size.should eql 43
  end
end