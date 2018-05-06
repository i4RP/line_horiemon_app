require 'sinatra'
require 'line/bot'
require 'mail'

# 微小変更部分！確認用。
get '/' do
  "Hello world"
end

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        #メール送信
        mail_from   = 'shoei0205@gmail.com'
        mail_passwd = 'ieoouhnfaxrebkcc'
        mail_to     = 'qa@ml.snskk.com'
        mail_subject= 'QAコーナー'
        mail_body   = "
        ・登録メールアドレス：shoei0205@gmail.com
        ・購読媒体名：まぐまぐ
        ・質問：
        現在大学を休学しブロックチェーン関連の事業をしている者です。
        #{event.message['text']}"
        message = {
          type: 'text',
          text: mail_body
        }

        Mail.defaults do
          delivery_method :smtp, {
            :address => 'smtp.gmail.com',
            :port => 587,
            :domain => 'example.com',
            :user_name => "#{mail_from}",
            :password => "#{mail_passwd}",
            :authentication => :login,
            :enable_starttls_auto => true
          }
        end

        m = Mail.new do
          from "#{mail_from}"
          to "#{mail_to}"
          subject "#{mail_subject}"
          body "#{mail_body}"
        end

        m.charset = "UTF-8"
        m.content_transfer_encoding = "8bit"
        m.deliver

        client.reply_message(event['replyToken'], message)
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        response = client.get_message_content(event.message['id'])
        tf = Tempfile.open("content")
        tf.write(response.body)
      end
    end
  }
  "OK"
end
