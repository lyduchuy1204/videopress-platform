{
  "attachments": [
    {
      "color": "{{COLOR}}",
      "blocks": [
        {
          "type": "header",
          "text": { "type": "plain_text", "text": "{{TITLE}}" }
        },
        {
          "type": "section",
          "fields": [
            { "type": "mrkdwn", "text": "*Env:* {{ENV}}" },
            { "type": "mrkdwn", "text": "*Build:* <{{BUILD_URL}}|#{{BUILD_NUMBER}}>" },
            { "type": "mrkdwn", "text": "*Actor:* {{ACTOR}}" },
            { "type": "mrkdwn", "text": "*Commit:* `{{GIT_SHA}}`" }
          ]
        },
        {
          "type": "section",
          "text": { "type": "mrkdwn", "text": "{{MESSAGE}}" }
        }
      ]
    }
  ]
}
