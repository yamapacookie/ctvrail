# README

## バージョン
- Ruby 3.0.4
- Rails 7.0.4

## デプロイ先
railway.app

## ビルダー
Dockerfile（Nixpacks）

## 外部サーバー
Redis

## 外部サービス
fly.io
Google Apps Script
Github Actions

## 環境変数
- MALLOC_ARENA_MAX = 2
- DISCORD_BOT_TOKEN
- DATABASE_URL
- CYTUBE_USER_ID
- CYTUBE_PASS
- CYTUBE_CHANNEL
- BOT_COMMENT_CHANNEL
- GAS_MAIL_ADDRESS

## 構成
fly.ioにフロントとデータベース立てて、Railway.appから接続している。
fly.ioはVMが貧弱で、Railwayは無料枠が厳しいのでそれぞれを補うように分割した。
こちらはredis/sidekiq/sidekiq-schedulerによる、worker（スクリプト）としてのみ運用。
メモリ削減のため、process_forkというメソッドでworker実行後、forkして捨てる方法を用いている。

また、登録エラーが発生した場合に備えて管理者にメールを自動で送信するシステムをいれているが
RailsのActionMailerを使うとメモリを喰うので、Google Apps ScriptにGETリクエストを送って
GASからメールを送るように設定している。

またメモリ削減のため、定期的にGithub Actionsで午前3時半と午後3時半ごろに再デプロイしている。

## 使い道
定時にCytubeへランダムなプレイリストを生成し自動登録する。
登録する動画の構成は、出現頻度の重みづけにより調整される。
また、新動画と再生不可になった動画をDiscordに定時報告する。