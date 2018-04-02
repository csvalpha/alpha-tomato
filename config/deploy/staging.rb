set :branch, :disable_bullet_exceptions_in_dev
set :deploy_to, '/opt/projects/alpha-tomato-staging'

before :"deploy:started", 'docker:compose:down'
after :"docker:deploy:compose:start", 'docker:deploy:compose:migrate'

set :docker_compose, true

set :linked_files, %w[.env]
set :linked_dirs, fetch(:linked_dirs, []).concat(%w[log])
