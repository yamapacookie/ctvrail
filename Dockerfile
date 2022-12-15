FROM ruby:3.0.4
ARG EnvironmentVariable

# ビルド時に実行するコマンドの指定
# インストール可能なパッケージの一覧の更新
RUN apt-get update -qq \
# パッケージのインストール（nodejs、postgresql-client、npmを指定）
&& apt-get install -y nodejs postgresql-client npm \
&& rm -rf /var/lib/apt/lists/* \
&& npm install --global yarn

# Chrome のインストール
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add \
  && echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -qq \
  && apt-get install -y google-chrome-stable libnss3 libgconf-2-4

# ChromeDriver のインストール
# 現在の最新のバージョンを取得し、それをインストールする。
RUN CHROMEDRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` \
  && curl -sS -o /tmp/chromedriver_linux64.zip http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip \
  && unzip /tmp/chromedriver_linux64.zip \
  && mv chromedriver /usr/local/bin/

WORKDIR /app
COPY Gemfile /app
COPY Gemfile.lock /app
RUN bundle install

COPY . /app

RUN mkdir -p tmp/pids

CMD ["bundle", "exec", "sidekiq"]