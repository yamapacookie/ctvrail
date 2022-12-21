# README

* バージョン
Ruby 3.0.4
Rails 7.0.4

* デプロイ先
railway.app

* ビルダー
Docker

* 外部サーバー
Redis

* 環境変数
MALLOC_ARENA_MAX = 2
DISCORD_BOT_TOKEN
DATABASE_URL
CYTUBE_USER_ID
CYTUBE_PASS
CYTUBE_CHANNEL
BOT_COMMENT_CHANNEL

* 構成
fly.ioにフロントとデータベース立てて接続している。
fly.ioはVMが貧弱で、Railwayは無料枠が厳しいのでそれぞれを補うように分割した。
こちらはredis/sidekiq/sidekiq-schedulerによる、workerとしてのみ運用。
メモリ削減のため、process_forkというメソッドでworker実行後、forkして捨てる設定。

* 使い道
定時にCytubeへランダムなプレイリストを生成し自動登録する。
登録する動画の構成は、出現頻度の重みづけにより調整される。
また、新動画と再生不可になった動画をDiscordに定時報告する。