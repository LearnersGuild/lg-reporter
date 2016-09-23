require './slack'

require 'asana'
require 'httparty'

class Reporter
  PAGINATION_LIMIT = 50 # high limit

  attr_reader :asana, :workspace

  def initialize(asana_token, asana_workspace_id)
    @asana = Asana::Client.new do |c|
      c.authentication :access_token, asana_token
    end

    @workspace = @asana.workspaces.find_by_id(asana_workspace_id)
  end

  def default_opts
    {
      fields: [ 'name', 'owner.name', 'current_status', 'public' ],
      expand: [ 'current_status' ]
    }
  end

  def reports(team_name)
    projects(team_name).map do |proj|
      name = proj.name
      proj_link = "https://app.asana.com/0/#{proj.id}/list"
      status_text = 'No status. Is this project active?'
      color = nil
      owner_name = proj.owner && proj.owner['name']
      timestamp = nil

      if proj.current_status
        status_text = proj.current_status['text']
        color = translate_color_to_slack(proj.current_status['color'])
        timestamp = parse_ts(proj.current_status['modified_at'])

        one_week_ago = Time.now.to_i - (7 * 24 * 60 * 60)
        status_text = 'No update in the last week.' if timestamp < one_week_ago
      end

      { title: name,
        title_link: proj_link,
        author_name: owner_name,
        text: status_text,
        ts: timestamp,
        color: color }
    end
  end

  def goals(options = nil)
    asana.projects \
         .find_all( workspace: workspace.id,
                    archived: false,
                    per_page: PAGINATION_LIMIT,
                    options: options || default_opts ) \
         .select { |p| p.name[0] == '!' }
  end

  def projects(team_name, options = nil)
    team = team(team_name)
    asana.projects \
         .find_all( workspace: workspace.id,
                    team: team.id,
                    archived: false,
                    per_page: PAGINATION_LIMIT,
                    options: options || default_opts ) \
         .reject { |p| (p.name[0] =~ /[&_]/) || p.archived || !p.public }
  end

  def team(team_name)
    asana.teams.find_by_organization(organization: workspace.id) \
         .find { |t| t.name.downcase == team_name.downcase }
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

  def parse_ts(date)
    Date.parse(date).to_time.to_i
  end
end

if $PROGRAM_NAME == __FILE__
  require 'dotenv'
  Dotenv.load

  r = Reporter.new(ENV['ASANA_TOKEN'], ENV['ASANA_WORKSPACE_ID'])

  action, arg = ARGV[0..1]
  p r.send(action.to_sym, arg)
end
