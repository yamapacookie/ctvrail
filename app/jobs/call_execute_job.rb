class CallExecuteJob < ApplicationJob
    def perform
      puts '定期実行成功'
    end
  end