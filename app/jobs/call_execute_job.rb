class CallExecuteJob < ApplicationJob
  def perform
    process_fork do
    
    # 起動メッセージ
    puts "定期実行を開始します"

      # selenium初期設定
      require 'selenium-webdriver'

      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--headless')
      options.add_argument('--no-sandbox')
      options.add_argument('--disable-dev-shm-usage')
      driver = Selenium::WebDriver.for :chrome, options: options

      puts 'yahooにアクセスします'

      driver.navigate.to 'https://www.yahoo.co.jp/' # ログインページ

      puts 'yahooにアクセスしました'

    # 初期値

    begin

    max = Setting.find(1)[:playlist] #プレイリストに登録する上限数
    channel = ENV['CYTUBE_CHANNEL']  #　Cytubeチャンネル
    cyid = ENV['CYTUBE_USER_ID']  # ログインID
    cypass = ENV['CYTUBE_PASS']  #　ログインパスワード
    intrvl = Setting.find(1)[:intervaldays]  # プレイリスト総入れ替えする日数間隔
    hour = Setting.find(1)[:swaptime]  # プレイリスト総入れ替えする時間
    inttime = Setting.find(1)[:intervaltime] #　補充時間間隔
    url = "https://cytube.mm428.net/r/" + channel # チャンネルのアドレス
    bot_token = ENV['DISCORD_BOT_TOKEN'] # Discordbotのtoken
    bot_chan = ENV['BOT_COMMENT_CHANNEL'] # Botの報告するチャンネル先
    tagtemp1 = Tagtemp.find(1) # 制限タグ
    uptemp1 = Uptemp.find(1) #補正タグ
    bottime = "23" #botの起動時間（0-24時指定）
    ENV['TZ'] = "Asia/Tokyo"  # タイムゾーン設定
    rty_cn = 0  # 登録作業の試行回数を制限
    rty_max = 3 # 試行回数の上限

    rescue
      puts "データベースへの接続ができません。fly.io側が弾いている可能性があるので仮想マシーンを再起動してください"

      # GASのメール送信スクリプトにGETリクエストを送る
      require "net/http"
      uri = URI.parse(ENV['GAS_MAIL_ADDRESS']+"?paas=flyio_kill_db")
      response = Net::HTTP.get_response(uri)
      response.code

    end

    require 'time'

    # 時間間隔の配列産出
    puts "時間間隔を設定します"
    hary = [*0..23].select{|h| h % inttime == 0 }
    tary = hary.map{|h| h.to_s + ":00"}
    table = tary.map{|t|Time.parse(t)}

    # 現在時間を１時間ごとに記述
    t = Time.now.to_i / 3600
    hnow = Time.at(t * 3600)

    puts "現在時間は"
    p hnow

    # プレイリスト入れ替えの判定用のメソッド
    def checkcal(interval,time)

      # 初期値
      time = time.to_s + ":00"
      regtime = Time.parse(time)  # 設定時間
      start_d = Date.new(Date.today.year,1,1)

      # 現在時間を60分ごとの表記に変換
      d = Time.now.to_i / 3600
      now = Time.at(d * 3600)

      # うるう年と通常年の、変数間隔の日付の配列を生成
      if Date.today.year % 4 == 0

          date = [*0..365]
          select_d = date.select{|x|x % interval == 0 }
          ary_d = select_d.map{|x|start_d + x}

      else

          date = [*0..364]
          select_d = date.select{|x|x % interval == 0 }
          ary_d = select_d.map{|x|start_d + x}

      end

      # 現在時間が、設定日と設定時間か検査
      if ary_d.include?(Date.today) && now == regtime then
          return true
      else
          return false
      end

    end #checkcal定義終了

    # 設定日、設定時間か調べる
    check = checkcal(intrvl,hour)

    # 登録時間もしくは総入れ替えタイミングかのチェック
    if check or table.include?(hnow) then
      rgst_time = true
    else
      rgst_time = false
    end

    # 一時停止判定と、指定時間かを判定
    if Setting.find(1)[:suspension] && rgst_time then

      # 条件判定確認用メッセージ
      puts "登録時間を満たしています"

      #失敗した場合の保険
      begin

        # DBコネクションを一旦切っておく
        ActiveRecord::Base.connection.close
        puts 'seleniumを起動します'

        # selenium初期設定
        require 'selenium-webdriver'

        options = Selenium::WebDriver::Chrome::Options.new
        options.add_argument('--headless')
        options.add_argument('--no-sandbox')
        options.add_argument('--disable-dev-shm-usage')
        driver = Selenium::WebDriver.for :chrome, options: options

        driver.navigate.to 'https://www.yahoo.co.jp/' # ログインページ

        puts 'yahooに接続しました'

        # 表示待機時間
        wait = Selenium::WebDriver::Wait.new(:timeout => 10)
        wait.until {driver.find_element(:xpath, '/html/body/div/section/div/div/form/button').displayed?}

        # 入力、ログインボタンクリック
        driver.find_element(:xpath, '/html/body/div/section/div/div/form/div[1]/input').send_keys cyid
        driver.find_element(:xpath, '/html/body/div/section/div/div/form/div[2]/input').send_keys cypass
        driver.find_element(:xpath, '/html/body/div/section/div/div/form/button').click

        sleep 3

        puts "ログインしました"

        driver.navigate.to 'https://cytube.xyz/r/' + channel  # 動画ページ移動

        puts "登録ページに移動します"
        
        # 表示に時間がかかるので長めに30秒待機
        sleep 30

        # もし総入れ替えの時間の場合、プレイリストをクリアする
        if check then

            puts "総入れ替えを行います"

            # プレイリストのID番号を取得する
            if driver.find_elements(:class => 'queue_entry').any? then

              nary = driver.find_elements(:class => 'queue_entry')
              nary = nary.map{|t|t.attribute('class')}
              nary = nary.select{|t| t.include?('pluid')}
              nary = nary.map{|t|t[/\d+/]}

              # 再生中の動画以外削除
              nary.each do |pid|

    pik = <<EOS

    let li=$(".pluid-"+#{pid});
    if(!li.hasClass("queue_active")){
      socket.emit("delete",#{pid});
    }

EOS
            driver.execute_script(pik)

            end

            driver.navigate.refresh

            sleep 20 # 更新後の待機時間

          end #ID取得終了

            list_size = driver.find_element(:id, 'plcount').text.to_i

            puts "総クリア後のプレイリスト数"
            p list_size

        else

          # プレイリスト数を取得する
          list_size = driver.find_element(:id, 'plcount').text.to_i

          puts "プレイリスト数"
          p list_size

        end # 総入れ替えここまで

        # 登録上限数から現在のリスト数の差をとる
        pcknum = max - list_size

        # 一回の登録数を600以下に抑える
        if pcknum < 0
          pcknum = 0
        elsif pcknum > 600
          pcknum = 600
        end

        # 現在のプレイリストの動画要素へアクセス
        puts 'プレイリストの動画要素へアクセスします'

        cylist = []
        cylist = driver.find_elements(:xpath ,"//ul[@id='queue']/li/a")

        # すでにプレイリストに動画が存在するかの確認
        if cylist.any? then

          puts 'プレイリストに登録されている動画が存在するので、アドレスを確認します。'

          # アドレスを取得
          cylist = cylist.map{|x| x.attribute('href')}

          # 取得したアドレスの表記揺れを整形
          cylist = cylist.map{|x| x.sub(/http:/,"https:")}
          cylist = cylist.map{|x| x.sub(/\/\/youtube\.com/,"//www.youtube.com")}
          cylist = cylist.map{|x| x.sub(/\/\/youtu\.be/,"www.youtube.com")}

          p cylist

        end # cylist.any?終了

        # 制限枠タグの参照データをテーブルから取得

        puts '制限枠のタグデータをDBから取得します'

        tt = JSON.parse(tagtemp1.to_json)
        tt.delete("id")
        tt.delete("none")
        tt.delete("created_at")
        tt.delete("updated_at")
        tagtem = tt

        puts '制限枠データを取得しました。'

        # 補正枠タグの参照データをテーブルから取得

        puts '補正枠のタグデータをDBから取得します'

        up = uptemp1.attributes
        up.delete("id")
        up.delete("created_at")
        up.delete("updated_at")
        uptem = up.to_a

        puts "下記は補正枠の配列化データです"
        p uptem

        # データベースに再接続
        ActiveRecord::Base.establish_connection

        # 動画データベースからランダムにアドレスとタグの二次元配列呼び出し
        ary = Clist.where.not(available: false).pluck(:address,:tag)

        # 再生不能疑惑のある動画を一端配列から除去する
        sus_ary = Clist.where("(status = ?) OR (status = ?)","susp1","susp2").pluck(:address,:tag)
        ary = ary - sus_ary

        # 各動画のタグつき動画の数をカウントする
        ary_size = ary.size
        ary_tag = ary.transpose[1]  # 全動画のタグのみの配列
        tag_name = tagtem.keys  # 制限和タグの名前配列
        tempnum = []  # タグ別の出現数

        puts "呼び出し配列数"
        p ary.size

        # 補正枠タグのデータから実際の重みデータを算出
        uhash = {}
        uptem.each do |u|
          u1 = Clist.where(tag: u[0]).size.to_f #タグの動画数
          rate = u1 / ary_size  # タグの動画の全体に対する割合
          rate = rate * u[1] * 100
          uhash.store(u[0],rate.to_i)  # 補正された割合の組（千分率）
        end

        puts "uhashの値"
        p uhash
        puts "必要計算前のtagtem"
        p tagtem

        # 補正タグの数値と合成して、各割合の枠を確定する
        shash = tagtem.merge(uhash)
        none_v = 10000 - shash.values.inject(:+)
        shash.store("none", none_v)
        tag_name = shash.keys

        p "shash"
        p shash
        p "tag_name"
        p tag_name

        # 全動画の各制限タグの動画数を算出
        tag_name.each do |t|

          t_num = ary_tag.count(t)
          tempnum.push(t_num)

        end

        p "tempnum"
        p tempnum

        # タグの動画数から、補正なしの場合の実出現率を算出
        thash = [tag_name,tempnum].transpose
        thash = Hash[*thash.flatten]
        thash = thash.transform_values{ |x| x * 1000 / ary_size } # タグ別の動画数を実出現率に計算し直す

        # 指定出現率と通常出現率の除算から、必要な重みを計算
        tag_name.each do |t|

          a = shash[t] * 100 / thash[t]
          thash[t] = a

        end

        puts "以下が元の重みデータ"
        p tagtem
        puts "以下が算出された重みデータ"
        p thash
        puts "登録されるべきプレイリストのサイズ"
        p pcknum

        # 重みのハッシュを参照して、タグを重みに翻訳
        ary.each{|x| x[1] = thash.fetch(x[1])}

        # ハッシュ化
        hash = Hash[*ary.flatten]

        # ハッシュから、現在のリストの動画を取り除く
        if cylist.any? then
          cylist.each{|cy| hash.delete(cy)}
        end

        # 再生不能疑惑のある動画を取得
        suspicion = Clist.where("(status = ?) OR (status = ?)","susp1","susp2").pluck(:address)

        # 登録数が少なくとも1つ以上のきのみ登録作業を行う
        if pcknum > 0 or suspicion.size > 0 then

          # 登録数が1以上の場合のみ抽選を行う
          if pcknum > 0 then

            # 抽選
            require 'pickup'
            playlist = Pickup.new(hash, uniq: true).pick(pcknum)

            # 登録プレイリストが2つ以上あるときのみ順番をシャッフルし、ひとつのときは配列に変換
            if playlist.class == Array && playlist.size > 1
              playlist = playlist.shuffle
            elsif playlist.class == String
              playlist = Array.new(1,playlist)
            end

          elsif pcknum == 0

            playlist = []

          end

          # 無効動画判定のためにこの時点でYouTube動画だけ抽出しておく
            youtube_list = []
            playlist.each do |y|
              if y.include? "youtube.com"
                id_y = y[/.*v=(.{11})$/,1]
                youtube_list.push(id_y)
              end
            end

            puts "登録予定のyoutube動画の数"
            puts youtube_list.size

          # 死んだ疑惑の動画を検出し、リストに加える
          playlist = playlist + suspicion

          puts "今から登録する予定の動画リストです"
          p playlist

        # 登録
        unless playlist.empty? then

          playlist.each do |videourl|

        scriptQueue = <<EOS
const data = parseMediaLink('#{videourl}')

socket.emit('queue', {
duration: undefined,
pos: "end",
temp: true,
title: undefined,
id: data.id,
type: data.type,
stime: data.stime
});
EOS

          driver.execute_script(scriptQueue)

          # おそらくcytubeが動画登録に1秒間隔なので余裕を持って1.2秒設定
          sleep 1.2

          end

          # 保険的に動画数の1割程度の時間待機
          sleep playlist.size * 0.1
          puts "登録を完了しました。"

          # DBコネクションを一旦切っておく
          ActiveRecord::Base.connection.close

          end #登録作業終了

          # 再生不可能な動画リストのため、アラートの動画リストを取得
          if driver.find_elements(:xpath, "//div[@class='alert alert-danger']").any? then
          d = driver.find_elements(:xpath, "//div[@class='alert alert-danger']")

          # リストを定義
          ary = []
          dllist = []
          idlist = []
          idlist_yt = []

          # 既に登録されてるアラートのオブジェクトを取り除く
          d.each do |d|
            if d.text.include?("このアイテムはすでにプレイリストに登録されています").! && d.text.include?("This item is already on the playlist").!
              ary.push(d)
            end
          end

          # 余ったアラームからリンクを取得
          if ary.any? then
            ary.each do |d|
              d.find_elements(:tag_name, 'a').each do |a|
                # ヘッド表示からアドレスを取得
                dllist.push(a.attribute('href'))
              end
            end
          end

            # dllistが空ではないか確認
            if dllist.any? then
              # 文字列を解析して動画ID（idlist）を抽出
              dllist.each do |l|

                  if l.include?("youtu.be")
                    a = l[/youtu\.be\/(.{11})/,1]
                    idlist.push(a)
                    idlist_yt.push(a)
                  elsif l.include?("nicovideo")
                      idlist.push(l[/nicovideo.{3,10}(sm\d{1,10})/,1])
                  elsif l.include?("vimeo.com")
                      idlist.push(l[/vimeo\.com\/(\d{1,10})/,1])
                  elsif l.include?("dailymotion")
                      idlist.push(l[/dailymotion\.com\/video\/([^$]{7})/,1])
                  end

              end

              # ログ確認用のシステムメッセージ
              puts "以下は無効な動画のID一覧です"
              p idlist

              puts "以下はboo前のエラー確認のための変数確認です"
              p youtube_list
              p idlist_yt

              # 無効なYoutube動画のIDが登録しようとしたYouTubeの動画IDと完全一致するか調べる
              boo = youtube_list - idlist_yt == [] && idlist_yt - youtube_list == []

              # エラー確認のために変数の確認
              puts "以下はboo後の変数の確認です"
              p boo
              p youtube_list
              p idlist_yt

              if boo && idlist_yt.length > 5
                yt_nomatch = false
                puts "Youtubeの登録動画と弾かれた動画が完全一致しています。cytubeがAPI弾かれている可能性が高いです。"
              elsif
                yt_nomatch = true
                puts "Youtubeの登録動画との一致はしていません。"
              end

              puts yt_nomatch

              # idリストが存在し100以下の場合、データベースを検索、該当項目の生存を無効に変更
              if idlist.any? && idlist.size < 100 && yt_nomatch then
                
                puts "無効動画がいくつかあるので、無効化の作業を行います。"
                
                # データベースに再接続
                ActiveRecord::Base.connection.close
                ActiveRecord::Base.establish_connection
                
                idlist.each do |d|

                  # 誤検知を均すために三回連続して検知したものだけ無効化する
                  if Clist.find_by(videoid: d).status == nil
                    Clist.find_by(videoid: d).update(status: "susp1")
                  elsif Clist.find_by(videoid: d).status == "susp1"
                    Clist.find_by(videoid: d).update(status: "susp2")
                  elsif Clist.find_by(videoid: d).status == "susp2"
                    Clist.find_by(videoid: d).update(available: false, status: "invalid")
                  end # if Clist.find_by

                end # idlist.each

              end # idlist.any?

              # YouTubeの動画が全て弾かれていた場合の制御
              if !yt_nomatch then

                puts 'YouTube動画の登録が全て弾かれたので、自動登録をオフにし、Discordに連絡します'

                # データベースに再接続
                ActiveRecord::Base.connection.close
                ActiveRecord::Base.establish_connection

                # botの自動登録を一時停止に切り替え
                Setting.find(1).update(suspension: false)
                puts 'botの自動登録をオフにしました'

                # discordbotによる一時停止の告知メッセージ
                require 'discordrb'
                bot = Discordrb::Bot.new token:bot_token

                msg = "Cytube内でYouTubeの動画の登録が出来ない状況を検知し、自動登録を一時停止に切り替えました。
                運営の方は、しばらくしてYouTube動画の登録が可能になったのを確認して、登録所の自動登録を有効化してください"

                bot.send_message(ENV['BOT_WARN_CHANNEL'], msg)

                puts 'Discordに自動登録をオフにしたメッセージを送りました'

                return

                bot.run

              end # if yt_nomatch
              
            end # if dllist.any?

          end # pcknum > 0

        end #再生不可能動画の取得、無効化終了

        puts 'ブラウザを終了します'

        driver.quit # ブラウザ終了

      rescue #失敗時の保険用のリトライ

        puts "なんらかのエラーで弾かれてるので再度登録を行おうとしています"
        
        # cytube側のエラーでスクリプトが永久に回り続けるのを防止
        rty_cn += 1

        sleep 30
        
        if rty_cn < 4
          puts "#{rty_cn}回目のリトライを行います。最大#{rty_max}回行います"
        end

        # 3回以上失敗した場合、メールで通知
        if rty_cn > 3

          # GASのメール送信スクリプトにGETリクエストを送る
          require "net/http"
          uri = URI.parse(ENV['GAS_MAIL_ADDRESS']+"?paas=rail")
          response = Net::HTTP.get_response(uri)
          response.code

        end

        retry if rty_cn <= rty_max

      end

    end #seleniumを動かす条件判定ここまで


    # 設定時かどうかを調べて自動報告用のbot起動
    bottime = bottime + ":00"

    # データベースに再接続
    ActiveRecord::Base.connection.close
    ActiveRecord::Base.establish_connection
    
    if Setting.find(1)[:suspension] && hnow == Time.parse(bottime) then

      # bot準備

      puts 'bot起動の判定を満たすので、botを起動します'

      require 'discordrb'
      bot = Discordrb::Bot.new token:bot_token

      # 無効動画と新規投稿動画、無効疑い動画の取得
      ary_delete = Clist.where(status: "invalid").pluck(:title,:address)
      ary_new = Clist.where(status: "new").pluck(:registrant,:address,:tag)
      ary_susp = Clist.where("(status = ?) OR (status = ?)","susp1","susp2").pluck(:id)

      # 無効動画があった場合、報告
      unless ary_delete.empty? then

        dlt ="再生不能が確認された動画は以下です。\n\n"

        # タイトルとアドレスの二次元配列を報告書式に変換
        ary_delete.each{|d| dlt = dlt + d[0] + "\n" + d[1] + "\n" }

        # 報告
        bot.send_message(ENV['BOT_COMMENT_CHANNEL'],dlt.chop)
        # ステータスを平常に戻す
        Clist.where(status: "invalid").update_all(status: nil)

      end #無効動画報告終了

      # 新登録動画があった場合、報告
      unless ary_new.empty? then

        # 初期値
        head = ary_new.transpose[0].uniq
        enttext = "本日、追加された動画は以下です。\n\n"
        ref = {"vtuber" => "Vtuber","midcast" => "中時間配信","longcast" =>"長時間配信",
        "gamecast"=>"ゲーム実況","asmr"=>"ASMR","krnkamn"=>"くろねこあまね","mimi"=>"銘々",
        "series"=>"長編シリーズ","thvoiced"=>"東方ボイスドラマ"}
        pary = []
        bary = []

        # 制限タグを動画アドレスに付加
        ary_new.each do |t|
          if t[2] != "none"
            t[1] = t[1] + " (補正タグ:" + ref[t[2]] + ")"
          end
        end

        # 動画リストから項目の配列を生成
        head.size.times do |cnt|
          ary = []
          ary_new.each do |b|
              if head[cnt] == b[0]
                  ary.push(b[1])
              end
          end

          ary = ary.each_slice(5).to_a
          text = "登録者：" + head[cnt]
          ary[0].unshift(text)
          pary.push(ary)

        end #報告配列終了

        pary = pary.flatten(1)

        # 項目の配列を実際に報告する書式の配列にする
        pary.size.times do |cnt|

            text = ''

            pary[cnt].each do |a|
                text = text + a.to_s + "\n"
            end

            text.chop!
            bary.push(text)


        end #書式変換終了

        bary[0] = enttext + bary[0]

        # 新規登録動画をコメント
        bary.each do |comment|
          bot.send_message(bot_chan, comment)
        end

        puts "botの報告作業を完了しました"

        # ステータスを平常に戻す
        Clist.where(status: "new").update_all(status: nil)

      end # 動画報告条件終了

      puts "動画報告を終了します"

      # 容疑動画をクリア
      if ary_susp.any? then
        Clist.where("(status = ?) OR (status = ?)","susp1","susp2").update_all(status: nil)
      end

      puts "botの全作業を終了します"

      return

      bot.run

    end #bot終了

    puts '全作業を終了します。'
    sleep 5

    # メモリ解放のためrails再起動（意味がないようなのでコメントアウト中）
    # system("bundle exec rails restart")

  end #precess_fork
  end #perform

  # メモリ節約のためのメソッド
  def process_fork
    # tracking if the op failed for the Process exit
    config = ActiveRecord::Base.remove_connection
    pid = Process.fork do
      begin
        ActiveRecord::Base.establish_connection(config)

        # This is needed to re-initialize the random number generator after forking (if you want diff random numbers generated in the forks)
        srand

        # Run the closure passed to the fork_with_new_connection method
        yield

      rescue Exception => exception
        puts ("Forked operation failed with exception: " + exception)
      ensure
        ActiveRecord::Base.remove_connection
        Process.exit!
      end
    end
    ActiveRecord::Base.establish_connection(config)

    #return the process id
    Process.waitpid pid
  end

end