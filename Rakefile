# frozen_string_literal: true

require 'json'
# noinspection RubyResolve
require 'rubocop/rake_task'
require 'rspec/core/rake_task'

desc 'Runs app locally'
task :run do
  ruby 'solar_edge.rb'
end

desc 'Docker login'
task :docker_login do |_task|
  sh "docker login -u #{ENV['DOCKER_USERNAME']} -p #{ENV['DOCKER_PASSWORD']}"
end

desc 'Builds ands pushes multiarch image'
task :docker_buildx, [:version] => %i[docker_login] do |_task, args|
  version = if ENV['GITHUB_REF'].nil?
              args[:version].nil? ? 'latest' : args[:version]
            else
              ENV['GITHUB_REF'].gsub(%r{refs/.*/}, '')
            end

  sh 'docker run --rm --privileged multiarch/qemu-user-static --reset -p yes'
  sh 'docker buildx create --name multiarch --driver docker-container --use'
  sh 'docker buildx inspect --bootstrap'
  # rubocop:disable Layout/LineLength
  sh "docker buildx build --push --platform linux/amd64,linux/arm/v7,linux/arm64/v8 -t hferentschik/solar-edge:#{version} ."
  # rubocop:enable Layout/LineLength
end

desc 'Builds the Docker container'
task :docker_build do
  sh 'docker build -t solar-edge .'
end

desc 'Tags and pushes the Docker container'
task :docker_push, [:version] => %i[docker_build docker_login] do |_task, args|
  version = if ENV['GITHUB_REF'].nil?
              args[:version].nil? ? 'latest' : args[:version]
            else
              ENV['GITHUB_REF'].gsub(%r{refs/.*/}, '')
            end
  sh "docker tag solar-edge:latest hferentschik/solar-edge:#{version}"
  sh "docker push hferentschik/solar-edge:#{version}"
end

RuboCop::RakeTask.new
