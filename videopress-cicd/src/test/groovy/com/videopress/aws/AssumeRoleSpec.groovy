package com.videopress.aws

import spock.lang.Specification
import spock.lang.Subject

/**
 * Spock spec cho AssumeRole — verify cleanup credential trong finally block
 * dù body throw exception.
 */
class AssumeRoleSpec extends Specification {

  def script = Mock(Object) {
    getEnv() >> [
      JENKINS_OIDC_TOKEN: 'fake-oidc-token',
      BUILD_ID:           '42'
    ]
  }

  @Subject
  def assumeRole = new AssumeRole(script)

  def "throw assert nếu roleArn rỗng"() {
    when:
    assumeRole.withOidc('', { -> })

    then:
    thrown(AssertionError)
  }

  def "throw assert nếu body null"() {
    when:
    assumeRole.withOidc('arn:aws:iam::111:role/x', null)

    then:
    thrown(AssertionError)
  }

  def "cleanup credential ngay cả khi body throw"() {
    given:
    def cleanupCount = 0
    def cleanupScript = Mock(Object) {
      getEnv() >> [JENKINS_OIDC_TOKEN: 'tok', BUILD_ID: '1']
      sh(_) >> { String cmd ->
        if (cmd.contains('rm -f .aws-creds.sh')) cleanupCount++
      }
      withEnv(_, _) >> { List envs, Closure body -> body.call() }
    }
    def ar = new AssumeRole(cleanupScript)

    when:
    try {
      ar.withOidc('arn:aws:iam::111:role/x') { throw new RuntimeException('boom') }
    } catch (RuntimeException ignored) {
      // expected
    }

    then:
    cleanupCount >= 1
  }
}
