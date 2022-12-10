class CallExecuteJob < ApplicationJob
    def perform
      require 'selenium-webdriver'

      # Seleniumの準備
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--headless')
      options.add_argument('--no-sandbox')
      options.add_argument('--disable-dev-shm-usage')

      driver = Selenium::WebDriver.for :chrome, options: options

      # Seleniumの起動テスト
      driver.navigate.to 'https://www.yahoo.co.jp/'

      h1 = driver.find_element(:css, 'h1')
      puts h1.text

      driver.quit


      testdata = Clist.find(1)[:title]
      puts testdata
      puts 'congraturation regular execution!!'
    end
end