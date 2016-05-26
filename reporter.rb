require './slack'

require 'asana'
require 'httparty'
require 'pry'

class Reporter
  PAGINATION_LIMIT = 2

  attr_reader :asana, :workspace

  def initialize(asana_token, asana_workspace_id)
    @asana = Asana::Client.new do |c|
      c.authentication :access_token, asana_token
    end

    @workspace = @asana.workspaces.find_by_id(asana_workspace_id)
  end

  def reports(team_name)
    opts = {
      fields: [ 'name', 'owner', 'current_status' ],
      expand: [ 'owner', 'current_status' ]
    }

    projects(team_name, opts).select(&:current_status).map do |proj|
      text = proj.current_status['text']
      color = translate_color_to_slack(proj.current_status['color'])

      { text: text, color: color }
    end
  end

  def projects(team_name, options = {})
    team = team(team_name)
    asana.projects \
         .find_all( workspace: workspace.id,
                    team: team.id,
                    archived: false,
                    per_page: PAGINATION_LIMIT,
                    options: options ) \
         .reject { |p| p.name[0] =~ /[&_]/ }
  end

  def team(team_name)
    asana.teams.find_by_organization(organization: workspace.id) \
         .find { |t| t.name == team_name }
  end

  def user(name)
    asana.users.find_by_workspace(workspace: workspace.id) \
         .find { |u| u.name.downcase =~ /#{name.downcase}/ }
  end

  def translate_color_to_slack(color)
    {
      'green' => 'good',
      'yellow' => 'warning',
      'red' => 'danger'
    }[color]
  end
end

if $PROGRAM_NAME == __FILE__
  require 'dotenv'
  Dotenv.load

  r = Reporter.new(ENV['ASANA_TOKEN'], ENV['ASANA_WORKSPACE_ID'])

  action, arg = ARGV[0..1]
  p r.send(action.to_sym, arg)
end
