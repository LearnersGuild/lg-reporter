require 'sinatra'
require 'sinatra/json'
require 'rdiscount'

require './reporter'

unless ENV['RACK_ENV'] == 'production'
  require 'dotenv'
  Dotenv.load
end

post '/' do
  team = params['text'].chomp
  user = params['user_name']
  response_url = params['response_url']

  logger.info("Request Params:")
  logger.info(params)

  r = Reporter.new(ENV['ASANA_TOKEN'], ENV['ASANA_WORKSPACE_ID'])

  reports = r.reports(team)

  slack_message = Slack::Response.new("Reports for team #{team}:", 'in_channel')
  slack_message.attachments = reports

  res = slack_message.data

  logger.info("Response Body:")
  logger.info(res.to_json)

  json res
end
