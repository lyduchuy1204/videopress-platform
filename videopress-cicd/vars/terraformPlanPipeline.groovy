// vars/terraformPlanPipeline.groovy
//
// Pipeline plan-only chạy mỗi PR mở/push lên repo videopress-infrastructure.
// Mục đích: "khám sức khoẻ" PR Terraform + comment plan vào PR + CHẶN merge
// nếu phát hiện thay đổi nguy hiểm trên DynamoDB (schema change / destroy).
//
// Cách dùng:
//
//   @Library('videopress-cicd@v1.2.0') _
//   terraformPlanPipeline(
//     workdir:       'envs/uat',
//     targetEnv:     'uat',
//     awsRoleArn:    env.AWS_OIDC_UAT_ROLE,
//     githubToken:   'github-pat-pr-comment',
//     enableInfracost: true
//   )

import com.videopress.terraform.PlanRunner
import com.videopress.terraform.PlanReviewBot
import com.videopress.aws.AssumeRole

/**
 * Pipeline plan-only cho PR IaC.
 *
 * @param config Map:
 *   - workdir         {String}  Đường dẫn folder env, ví dụ 'envs/uat'.
 *   - targetEnv       {String}  uat|staging|prod (suy ra từ PR label nếu null).
 *   - awsRoleArn      {String}  Credential ID của OIDC role ARN.
 *   - githubToken     {String}  Credential ID của GitHub PAT để comment PR.
 *   - enableInfracost {Boolean} Default true.
 */
def call(Map config) {
  assert config.workdir     : "terraformPlanPipeline: missing 'workdir'"
  assert config.targetEnv   : "terraformPlanPipeline: missing 'targetEnv'"
  assert config.awsRoleArn  : "terraformPlanPipeline: missing 'awsRoleArn' (credential ID)"
  assert config.githubToken : "terraformPlanPipeline: missing 'githubToken' (credential ID)"
  config.enableInfracost = (config.enableInfracost == null) ? true : config.enableInfracost

  pipeline {
    agent any

    options {
      timeout(time: 25, unit: 'MINUTES')
      timestamps()
      ansiColor('xterm')
      // Build mới abort build cũ trên cùng PR.
      disableConcurrentBuilds(abortPrevious: true)
    }

    environment {
      WORKDIR    = "${config.workdir}"
      TARGET_ENV = "${config.targetEnv}"
    }

    stages {

      stage('Checkout') { steps { checkout scm } }

      stage('Format Check') {
        steps { dir(env.WORKDIR) { sh 'terraform fmt -check -recursive' } }
      }

      stage('Init') {
        steps {
          script {
            new AssumeRole(this).withOidc(config.awsRoleArn) {
              dir(env.WORKDIR) { sh 'terraform init -backend=true -input=false' }
            }
          }
        }
      }

      stage('Validate') {
        steps { dir(env.WORKDIR) { sh 'terraform validate' } }
      }

      stage('TFLint') {
        steps { dir(env.WORKDIR) { sh 'tflint --recursive' } }
      }

      stage('TFSec') {
        steps {
          dir(env.WORKDIR) {
            sh "${env.WORKSPACE}/resources/scripts/tfsec-wrapper.sh ."
          }
        }
      }

      stage('Plan') {
        steps {
          script {
            new AssumeRole(this).withOidc(config.awsRoleArn) {
              new PlanRunner(this).plan(env.WORKDIR, 'tfplan.bin')
              dir(env.WORKDIR) {
                sh 'terraform show -json tfplan.bin > plan.json'
                archiveArtifacts artifacts: 'tfplan.bin,plan.json', fingerprint: true
              }
            }
          }
        }
      }

      stage('Plan Review (DynamoDB safety)') {
        steps {
          script {
            def bot = new PlanReviewBot(this)
            def summary = bot.analyze("${env.WORKDIR}/plan.json")

            // CHẶN merge nếu phát hiện DynamoDB schema change hoặc destroy.
            if (summary.dynamoSchemaChange) {
              error("BLOCKED: DynamoDB SCHEMA CHANGE phát hiện ở ${summary.criticalResources}. Cần PR riêng + 2 reviewer + RFC.")
            }
            if (summary.dynamoDestroy) {
              error("BLOCKED: DynamoDB DESTROY phát hiện ở ${summary.criticalResources}. Bắt buộc 2 reviewer + RFC.")
            }
            // Lưu summary để stage tiếp theo dùng.
            env.PLAN_SUMMARY_JSON = groovy.json.JsonOutput.toJson(summary)
          }
        }
      }

      stage('Comment PR') {
        when { changeRequest() }
        steps {
          script {
            def bot = new PlanReviewBot(this)
            withCredentials([string(credentialsId: config.githubToken, variable: 'GITHUB_TOKEN')]) {
              try {
                bot.commentToPR(env.CHANGE_ID, env.PLAN_SUMMARY_JSON)
              } finally {
                // Cleanup biến môi trường nhạy cảm (defense-in-depth).
                sh 'unset GITHUB_TOKEN || true'
              }
            }
          }
        }
      }

      stage('Infracost diff') {
        when { expression { config.enableInfracost } }
        steps {
          dir(env.WORKDIR) {
            sh "${env.WORKSPACE}/resources/scripts/infracost-diff.sh plan.json"
          }
        }
      }
    }

    post {
      always { cleanWs notFailBuild: true }
    }
  }
}
