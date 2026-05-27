package com.videopress.notify

/**
 * Wrapper Slack incoming webhook.
 *
 * KHÔNG hardcode webhook URL — webhookCredId là Jenkins Secret text credential ID.
 */
class Slack implements Serializable {

  private static final long serialVersionUID = 1L

  def script
  String webhookCredId

  Slack(def script, String webhookCredId) {
    assert webhookCredId : "Slack: missing 'webhookCredId'"
    this.script = script
    this.webhookCredId = webhookCredId
  }

  /** Gửi message màu xanh (success). */
  def success(String text) { send(text, '#36a64f') }

  /** Gửi message màu đỏ (failure). */
  def failure(String text) { send(text, '#d50000') }

  /** Gửi message màu vàng (warning). */
  def warning(String text) { send(text, '#ffaa00') }

  private void send(String text, String color) {
    script.withCredentials([
      script.string(credentialsId: webhookCredId, variable: 'SLACK_WEBHOOK_URL')
    ]) {
      try {
        def payload = groovy.json.JsonOutput.toJson([
          attachments: [[
            color: color,
            text:  text,
            footer: "Jenkins • ${script.env.JOB_NAME ?: 'unknown'} #${script.env.BUILD_NUMBER ?: '?'}"
          ]]
        ])
        script.sh """
          set +x
          curl -sS -X POST -H 'Content-Type: application/json' \\
            -d '${payload.replaceAll("'", "\\\\'")}' "\${SLACK_WEBHOOK_URL}"
        """
      } finally {
        script.sh 'unset SLACK_WEBHOOK_URL || true'
      }
    }
  }
}
