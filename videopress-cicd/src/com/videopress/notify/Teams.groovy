package com.videopress.notify

/**
 * Wrapper Microsoft Teams incoming webhook.
 *
 * Gửi message dạng MessageCard (legacy) — đơn giản và phổ biến nhất.
 * Dùng template `resources/templates/teams-deploy.json.tpl` cho payload phức tạp.
 */
class Teams implements Serializable {

  private static final long serialVersionUID = 1L

  def script
  String webhookCredId

  Teams(def script, String webhookCredId) {
    assert webhookCredId : "Teams: missing 'webhookCredId'"
    this.script = script
    this.webhookCredId = webhookCredId
  }

  def success(String text) { send(text, '36A64F', '✅ Success') }
  def failure(String text) { send(text, 'D50000', '❌ Failure') }
  def warning(String text) { send(text, 'FFAA00', '⚠️ Warning') }

  private void send(String text, String themeColor, String title) {
    script.withCredentials([
      script.string(credentialsId: webhookCredId, variable: 'TEAMS_WEBHOOK_URL')
    ]) {
      try {
        def card = [
          '@type'    : 'MessageCard',
          '@context' : 'https://schema.org/extensions',
          summary    : title,
          themeColor : themeColor,
          title      : title,
          text       : text,
          sections   : [[
            facts: [
              [name: 'Job',     value: script.env.JOB_NAME ?: '-'],
              [name: 'Build',   value: "#${script.env.BUILD_NUMBER ?: '-'}"],
              [name: 'URL',     value: script.env.BUILD_URL ?: '-']
            ]
          ]]
        ]
        def payload = groovy.json.JsonOutput.toJson(card)
        script.sh """
          set +x
          curl -sS -X POST -H 'Content-Type: application/json' \\
            -d '${payload.replaceAll("'", "\\\\'")}' "\${TEAMS_WEBHOOK_URL}"
        """
      } finally {
        script.sh 'unset TEAMS_WEBHOOK_URL || true'
      }
    }
  }
}
