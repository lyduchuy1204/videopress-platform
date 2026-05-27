package com.videopress.aws

/**
 * Helper assume IAM Role qua OIDC (STS AssumeRoleWithWebIdentity).
 *
 * Mục đích:
 *   - Setup AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_SESSION_TOKEN
 *     trước khi chạy block AWS CLI.
 *   - TỰ ĐỘNG cleanup credential sau khi block kết thúc (try/finally).
 *
 * KHÔNG hardcode role ARN — nhận qua tham số. Pipeline gọi từ env var.
 */
class AssumeRole implements Serializable {

  private static final long serialVersionUID = 1L

  /** Reference tới pipeline `script` để gọi step Jenkins (sh, withCredentials, ...). */
  def script

  AssumeRole(def script) {
    this.script = script
  }

  /**
   * Chạy `body` closure với env var AWS_* đã được set qua AssumeRoleWithWebIdentity.
   * Cleanup biến môi trường sau khi xong (kể cả khi exception).
   *
   * @param roleArn    Credential ID (Jenkins) chứa role ARN; HOẶC ARN trực tiếp khi
   *                   chạy ngoài Jenkins (ưu tiên credential ID).
   * @param body       Closure chạy trong scope đã có credential.
   */
  def withOidc(String roleArn, Closure body) {
    assert roleArn : "AssumeRole.withOidc: 'roleArn' rỗng"
    assert body    : "AssumeRole.withOidc: thiếu closure body"

    // Trong Jenkins thật, dùng plugin `aws-credentials` + `withAWS` step.
    // Ở đây giữ skeleton: gọi sh assume-role-with-web-identity rồi export env.
    def webIdentityToken = script.env.JENKINS_OIDC_TOKEN ?: ''
    assert webIdentityToken : "AssumeRole.withOidc: env.JENKINS_OIDC_TOKEN chưa set"

    try {
      script.sh """
        set +x   # tránh log token
        OUT=\$(aws sts assume-role-with-web-identity \\
          --role-arn ${roleArn} \\
          --role-session-name jenkins-${script.env.BUILD_ID} \\
          --web-identity-token \${JENKINS_OIDC_TOKEN} \\
          --duration-seconds 3600 \\
          --output json)
        echo \"\$OUT\" | jq -r '.Credentials | \"export AWS_ACCESS_KEY_ID=\\(.AccessKeyId)\\nexport AWS_SECRET_ACCESS_KEY=\\(.SecretAccessKey)\\nexport AWS_SESSION_TOKEN=\\(.SessionToken)\"' > .aws-creds.sh
        chmod 600 .aws-creds.sh
      """
      script.withEnv(['AWS_CREDENTIALS_SOURCE=.aws-creds.sh']) {
        body.call()
      }
    } finally {
      // Defense-in-depth — wipe credential file.
      script.sh 'rm -f .aws-creds.sh || true'
      script.sh 'unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN || true'
    }
  }
}
