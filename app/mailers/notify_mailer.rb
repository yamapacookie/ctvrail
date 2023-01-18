class NotifyMailer < ApplicationMailer

    def send_mail

        mail(to: ENV['SendMailAddress'], subject: "エラーの通知/Railway")

    end

end
