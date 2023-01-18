class ApplicationMailer < ActionMailer::Base
  default from: "管理者 <#{ENV['SEND_MAIL_ADDRESS']}>"
  layout "mailer"
end
