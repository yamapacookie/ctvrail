class NotifyMailer < ApplicationMailer

    def send_mail

        mail(to: ENV['SEND_MAIL_ADDRESS'], subject: "エラーの通知/Railway")

    end

end
