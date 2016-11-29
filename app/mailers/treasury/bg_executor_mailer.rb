# coding: utf-8
module Treasury
  class BgExecutorMailer < ActionMailer::Base
    default from: DO_NOT_REPLY,
            return_path: DO_NOT_REPLY_RETURN_PATH

    def notify(recipient, subject, message, exception = nil)
      @message = message.to_s
      @exception = exception
      mail(to: recipient, subject: subject)
    end
  end
end
