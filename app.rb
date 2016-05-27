require 'sinatra'
require 'sinatra/json'
require 'rdiscount'
require 'httparty'

require './reporter'

unless ENV['RACK_ENV'] == 'production'
  require 'dotenv'
  Dotenv.load
end

post '/' do
  team = params['text'].chomp
  user = params['user_name']
  response_url = params['response_url']

  unless team.empty?
    logger.info("Request Params:")
    logger.info(params)

    Thread.new do
      r = Reporter.new(ENV['ASANA_TOKEN'], ENV['ASANA_WORKSPACE_ID'])
      reports = r.reports(team)

      slack_message = Slack::Response.new("Reports for team #{team}:")
      slack_message.attachments = reports

      res = slack_message.data
      HTTParty.post(response_url, { body: res.to_json, headers: { 'Content-Type' => 'application/json' } })
    end

    res = Slack::Response.new('Fetching data from Asana...').data
  else
    res = Slack::Response.new('No team provided. Must include the name of an Asana team.').data
  end

  logger.info("Response Body:")
  logger.info(res.to_json)

  json res
end
