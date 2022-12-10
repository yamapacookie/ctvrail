class CallExecuteJob < ApplicationJob
    def perform
      require 'selenium-webdriver'

      testdata = Clist.find(1)[:title]
      puts testdata
      puts 'congraturation regular execution!!'
    end
end