# Reporter

Project reports API for Learners Guild. Built for Slack integration.

Send a `HTTP POST` request to `/` with an Asana team name, get a report for all projects in that team.

```shell-session
$ curl -X POST https://lg-reporter.herokuapp.com/ -F 'text=LOS'
```

returns this JSON:

```json
{
    "attachments": [
        {
            "author_name": "Tanner Welsh",
            "color": null,
            "mrkdwn_in": [
                "text",
                "pretext"
            ],
            "text": "No status. Is this project active?",
            "title": "Curriculum deal done with Turing.io",
            "title_link": "https://app.asana.com/0/48990756448726/list",
            "ts": null
        },
    ],
    "mrkdwn": true,
    "response_type": "ephemeral",
    "text": "Reports for team LOS:"
}
```
