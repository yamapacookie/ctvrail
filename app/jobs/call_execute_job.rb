class CallExecuteJob < ApplicationJob
    def perform
      testdata = Clist.find(1)
      puts testdata
      puts 'congraturation regular execution!!'
    end
end