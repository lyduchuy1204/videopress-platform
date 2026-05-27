{
  "@type": "MessageCard",
  "@context": "https://schema.org/extensions",
  "summary": "{{TITLE}}",
  "themeColor": "{{THEME_COLOR}}",
  "title": "{{TITLE}}",
  "text": "{{MESSAGE}}",
  "sections": [
    {
      "facts": [
        { "name": "Env",     "value": "{{ENV}}" },
        { "name": "Build",   "value": "#{{BUILD_NUMBER}}" },
        { "name": "Actor",   "value": "{{ACTOR}}" },
        { "name": "Commit",  "value": "{{GIT_SHA}}" }
      ]
    }
  ],
  "potentialAction": [
    {
      "@type": "OpenUri",
      "name":  "Open Build",
      "targets": [{ "os": "default", "uri": "{{BUILD_URL}}" }]
    }
  ]
}
