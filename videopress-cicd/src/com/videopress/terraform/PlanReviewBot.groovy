package com.videopress.terraform

import groovy.json.JsonSlurper
import groovy.json.JsonOutput

/**
 * Class quan trọng nhất của shared library.
 *
 * Phân tích `plan.json` (output của `terraform show -json`) để phát hiện
 * thay đổi nguy hiểm trên tài nguyên CRITICAL — đặc biệt là DynamoDB.
 *
 * Cụ thể:
 *   - `dynamoDestroy`      : có resource `aws_dynamodb_table` bị `delete`?
 *   - `dynamoSchemaChange` : có table bị đổi `hash_key` / `range_key` / `attribute`,
 *                            hoặc bị `delete + create` (replace) bắt buộc?
 *   - `replaceCount`       : tổng số resource bị replace.
 *   - `destroyCount`       : tổng số resource bị destroy.
 *   - `criticalResources`  : danh sách address của resource critical bị đụng vào.
 *
 * Method `commentToPR()` dùng GitHub API post comment markdown lên PR
 * dựa trên template `resources/templates/plan-comment.md.tpl`.
 */
class PlanReviewBot implements Serializable {

  private static final long serialVersionUID = 1L

  /** Tài nguyên được coi là CRITICAL — sửa nhầm gây mất data hoặc lỗi toàn cục. */
  static final List<String> CRITICAL_TYPES = [
    'aws_dynamodb_table',
    'aws_cognito_user_pool',
    'aws_s3_bucket',
    'aws_kms_key'
  ]

  def script

  PlanReviewBot(def script) {
    this.script = script
  }

  /**
   * Phân tích plan JSON, trả về Map summary.
   *
   * @param planJsonPath  Path tới file `plan.json` (output của `terraform show -json`).
   * @return Map với các keys mô tả ở phần class doc.
   */
  Map analyze(String planJsonPath) {
    assert planJsonPath : "PlanReviewBot.analyze: 'planJsonPath' rỗng"

    def planText = script.readFile(planJsonPath)
    def plan     = new JsonSlurper().parseText(planText)
    def changes  = (plan?.resource_changes ?: []) as List

    def dynamoTables = changes.findAll { it.type == 'aws_dynamodb_table' }

    def dynamoDestroy = dynamoTables.any { c ->
      def actions = (c.change?.actions ?: []) as List
      'delete' in actions && !('create' in actions)
    }

    def dynamoReplace = dynamoTables.any { c ->
      def actions = (c.change?.actions ?: []) as List
      actions == ['delete', 'create'] || actions == ['create', 'delete']
    }

    def dynamoKeyChange = dynamoTables.any { c ->
      def before = c.change?.before ?: [:]
      def after  = c.change?.after  ?: [:]
      (before.hash_key  != after.hash_key)  ||
      (before.range_key != after.range_key)
    }

    def replaceCount = changes.count { c ->
      def a = (c.change?.actions ?: []) as List
      a == ['delete', 'create'] || a == ['create', 'delete']
    }
    def destroyCount = changes.count { c ->
      def a = (c.change?.actions ?: []) as List
      'delete' in a && !('create' in a)
    }

    def criticalAddresses = changes.findAll { c ->
      c.type in CRITICAL_TYPES &&
      ((c.change?.actions ?: []).any { it in ['delete', 'create', 'update'] })
    }.collect { it.address }

    return [
      dynamoDestroy:      dynamoDestroy,
      dynamoSchemaChange: dynamoKeyChange || dynamoReplace,
      replaceCount:       replaceCount,
      destroyCount:       destroyCount,
      criticalResources:  criticalAddresses
    ]
  }

  /**
   * Post comment markdown lên GitHub PR.
   *
   * @param prNumber  Số PR (env.CHANGE_ID khi chạy trong PR job).
   * @param summaryJson  Summary trả về từ analyze() đã JSON-encode.
   */
  void commentToPR(String prNumber, String summaryJson) {
    assert prNumber    : "commentToPR: 'prNumber' rỗng"
    assert summaryJson : "commentToPR: 'summaryJson' rỗng"

    def repo = script.env.GITHUB_REPOSITORY ?: 'videopress/videopress-infrastructure'
    def summary = new JsonSlurper().parseText(summaryJson)

    def body = renderTemplate(summary)
    def payload = JsonOutput.toJson([body: body])

    // GITHUB_TOKEN phải đã được inject qua withCredentials(...) ở stage gọi.
    script.sh """
      set +x
      curl -sS -X POST \\
        -H "Authorization: token \${GITHUB_TOKEN}" \\
        -H "Accept: application/vnd.github+json" \\
        https://api.github.com/repos/${repo}/issues/${prNumber}/comments \\
        -d '${payload.replaceAll("'", "\\\\'")}'
    """
  }

  /** Render template `plan-comment.md.tpl` với summary. */
  private String renderTemplate(Map summary) {
    def tpl = script.libraryResource('templates/plan-comment.md.tpl')
    def critical = summary.criticalResources?.collect { "- `${it}`" }?.join('\n') ?: '_(none)_'
    def planLine = "🔢 **${summary.replaceCount}** to replace · **${summary.destroyCount}** to destroy"
    return tpl
      .replace('{{PLAN_SUMMARY}}', planLine)
      .replace('{{COST_DIFF}}', script.env.INFRACOST_DIFF ?: '_(infracost not run)_')
      .replace('{{CRITICAL_LIST}}', critical)
  }
}
