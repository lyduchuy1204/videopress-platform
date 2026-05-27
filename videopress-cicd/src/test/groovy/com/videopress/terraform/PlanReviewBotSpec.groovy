package com.videopress.terraform

import spock.lang.Specification
import spock.lang.Subject

/**
 * Spock spec cho PlanReviewBot — class quan trọng nhất của shared library.
 *
 * Fixture: src/test/resources/fixtures/plan-with-dynamodb-destroy.json
 *          mô phỏng `terraform show -json` output có DynamoDB destroy + replace.
 */
class PlanReviewBotSpec extends Specification {

  def script = Mock(Object) {
    // Mock step `readFile` để trả về nội dung fixture.
    readFile(_) >> { String path -> new File("src/test/resources/${path}").text }
    libraryResource(_) >> { String path -> new File("resources/${path}").text }
  }

  @Subject
  def bot = new PlanReviewBot(script)

  def "phát hiện DynamoDB destroy từ fixture"() {
    when:
    def summary = bot.analyze('fixtures/plan-with-dynamodb-destroy.json')

    then:
    summary.dynamoDestroy      == true
    summary.dynamoSchemaChange == true
    summary.destroyCount       >= 1
    summary.criticalResources.any { it.contains('aws_dynamodb_table') }
  }

  def "plan rỗng không trigger flag"() {
    given:
    def emptyScript = Mock(Object) {
      readFile(_) >> '{"resource_changes": []}'
    }
    def emptyBot = new PlanReviewBot(emptyScript)

    when:
    def summary = emptyBot.analyze('whatever.json')

    then:
    summary.dynamoDestroy      == false
    summary.dynamoSchemaChange == false
    summary.replaceCount       == 0
    summary.destroyCount       == 0
    summary.criticalResources.isEmpty()
  }

  def "phát hiện schema change khi hash_key đổi"() {
    given:
    def planJson = '''
      {
        "resource_changes": [{
          "address": "aws_dynamodb_table.users",
          "type": "aws_dynamodb_table",
          "change": {
            "actions": ["update"],
            "before": {"hash_key": "user_id", "range_key": null},
            "after":  {"hash_key": "userId",  "range_key": null}
          }
        }]
      }
    '''.trim()
    def s = Mock(Object) { readFile(_) >> planJson }
    def b = new PlanReviewBot(s)

    when:
    def summary = b.analyze('x.json')

    then:
    summary.dynamoSchemaChange == true
  }

  def "throw assert nếu planJsonPath rỗng"() {
    when:
    bot.analyze('')

    then:
    thrown(AssertionError)
  }
}
