worker: /bin/bash -l -c "bundle exec sidekiq -C config/sidekiq.yml"
web: rails db:migrate && /bin/bash -l -c "bundle exec puma -C config/puma.rb"