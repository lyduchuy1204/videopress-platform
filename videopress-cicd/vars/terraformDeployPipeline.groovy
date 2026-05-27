// vars/terraformDeployPipeline.groovy
//
// Pipeline deploy IaC theo môi trường, có gate phù hợp với mức nhạy cảm:
//   - UAT:     auto, không approval.
//   - Staging: 1 approval + backup state.
//   - Prod:    2 approval + cooldown + backup DynamoDB + backup state +
//              chặn nếu plan có thay đổi DynamoDB schema/destroy.
//
// Cách dùng:
//
//   @Library('videopress-cicd@v1.2.0') _
//   terraformDeployPipeline(
//     environments:              ['uat', 'staging', 'prod'],
//     workdirOf:                 [uat: 'envs/uat', staging: 'envs/staging', prod: 'envs/prod'],
//     awsRoleArnOf:              [uat: env.AWS_OIDC_UAT, staging: env.AWS_OIDC_STG, prod: env.AWS_OIDC_PROD],
//     prodApprovers:             'devops-leads,sre-oncall',
//     prodCooldownMinutes:       30,
//     backupDynamoDbBeforeProd:  true,
//     stateArchiveBucket:        'videopress-state-archive',
//     teamsWebhook:              'teams-webhook-deploy'
//   )

import com.videopress.terraform.PlanRunner
import com.videopress.terraform.ApplyRunner
import com.videopress.terraform.PlanReviewBot
import com.videopress.aws.AssumeRole
import com.videopress.aws.S3StateBackup
import com.videopress.notify.Teams

/**
 * Pipeline deploy IaC theo env.
 *
 * @param config Map:
 *   - environments              {List<String>} Sub-set của ['uat','staging','prod'].
 *   - workdirOf                 {Map<env,String>}
 *   - awsRoleArnOf              {Map<env,String>}
 *   - prodApprovers             {String} Comma-separated user/group.
 *   - prodCooldownMinutes       {Integer} Default 30.
 *   - backupDynamoDbBeforeProd  {Boolean} Default true.
 *   - stateArchiveBucket        {String}
 *   - teamsWebhook              {String} Credential ID.
 */
def call(Map config) {
  assert config.environments       : "terraformDeployPipeline: missing 'environments'"
  assert config.workdirOf          : "terraformDeployPipeline: missing 'workdirOf'"
  assert config.awsRoleArnOf       : "terraformDeployPipeline: missing 'awsRoleArnOf'"
  assert config.stateArchiveBucket : "terraformDeployPipeline: missing 'stateArchiveBucket'"
  assert config.teamsWebhook       : "terraformDeployPipeline: missing 'teamsWebhook'"
  config.prodApprovers            = config.prodApprovers ?: 'devops-leads,sre-oncall'
  config.prodCooldownMinutes      = (config.prodCooldownMinutes ?: 30) as Integer
  config.backupDynamoDbBeforeProd = (config.backupDynamoDbBeforeProd == null) ? true : config.backupDynamoDbBeforeProd

  pipeline {
    agent any

    options {
      timeout(time: 90, unit: 'MINUTES')
      timestamps()
      buildDiscarder(logRotator(numToKeepStr: '100'))
    }

    parameters {
      choice(name: 'TARGET_ENV', choices: config.environments, description: 'Env cần deploy')
    }

    stages {
      stage('Plan') {
        steps {
          script {
            def env_ = params.TARGET_ENV
            def workdir = config.workdirOf[env_]
            def roleArn = config.awsRoleArnOf[env_]

            new AssumeRole(this).withOidc(roleArn) {
              new PlanRunner(this).plan(workdir, 'tfplan.bin')
              dir(workdir) { sh 'terraform show -json tfplan.bin > plan.json' }
            }

            // ⚠️ Chặn deploy nếu plan có DynamoDB destroy / schema change ở mọi env.
            def summary = new PlanReviewBot(this).analyze("${workdir}/plan.json")
            if (summary.dynamoSchemaChange || summary.dynamoDestroy) {
              error("BLOCKED: Plan của ${env_} có thay đổi DynamoDB nhạy cảm: ${summary.criticalResources}. Dừng pipeline.")
            }
          }
        }
      }

      stage('Backup state (Staging/Prod)') {
        when { expression { params.TARGET_ENV in ['staging', 'prod'] } }
        steps {
          script {
            def env_ = params.TARGET_ENV
            new S3StateBackup(this).backupBeforeApply(
              "videopress-tfstate-${env_}",
              "${env_}/terraform.tfstate",
              config.stateArchiveBucket
            )
          }
        }
      }

      stage('Backup DynamoDB (Prod)') {
        when {
          allOf {
            expression { params.TARGET_ENV == 'prod' }
            expression { config.backupDynamoDbBeforeProd }
          }
        }
        steps {
          script {
            new AssumeRole(this).withOidc(config.awsRoleArnOf['prod']) {
              ['Users-prod', 'Jobs-prod', 'Notifications-prod'].each { table ->
                sh """
                  aws dynamodb create-backup \
                    --table-name ${table} \
                    --backup-name pre-deploy-${env.BUILD_ID}-${table}
                """
              }
            }
          }
        }
      }

      stage('Approval — Staging') {
        when { expression { params.TARGET_ENV == 'staging' } }
        steps {
          script {
            timeout(time: 60, unit: 'MINUTES') {
              input message: 'Apply to STAGING?', submitter: 'devops-leads'
            }
          }
        }
      }

      stage('Approval — Prod (2 reviewer)') {
        when { expression { params.TARGET_ENV == 'prod' } }
        steps {
          script {
            // Cooldown — chống deploy panic.
            echo "⏳ Cooldown ${config.prodCooldownMinutes} phút trước approval prod..."
            sleep(time: config.prodCooldownMinutes, unit: 'MINUTES')

            timeout(time: 120, unit: 'MINUTES') {
              def approver1 = input(
                message: 'Apply to PROD — Approval 1/2',
                submitter: config.prodApprovers,
                submitterParameter: 'APPROVER_1',
                parameters: [string(name: 'RFC_LINK', defaultValue: '', description: 'RFC / change ticket link')]
              )
              def approver2 = input(
                message: "Apply to PROD — Approval 2/2 (1st: ${approver1.APPROVER_1})",
                submitter: config.prodApprovers,
                submitterParameter: 'APPROVER_2'
              )
              env.APPROVED_BY = "${approver1.APPROVER_1},${approver2}"
              echo "✅ Prod approved by ${env.APPROVED_BY} | RFC: ${approver1.RFC_LINK}"
            }
          }
        }
      }

      stage('Apply') {
        steps {
          script {
            def env_ = params.TARGET_ENV
            def workdir = config.workdirOf[env_]
            def roleArn = config.awsRoleArnOf[env_]

            // Lock 1 deploy / env / lúc.
            lock(resource: "${env_}-deploy", inversePrecedence: true) {
              new AssumeRole(this).withOidc(roleArn) {
                new ApplyRunner(this).apply(workdir, 'tfplan.bin')
              }
            }
          }
        }
      }

      stage('Smoke test') {
        steps {
          script {
            build job: "videopress-smoke-test-${params.TARGET_ENV}", wait: true
          }
        }
      }
    }

    post {
      success {
        script {
          new Teams(this, config.teamsWebhook).success(
            "✅ ${params.TARGET_ENV.toUpperCase()} deploy OK by ${env.APPROVED_BY ?: 'auto'} (#${env.BUILD_NUMBER})"
          )
        }
      }
      failure {
        script {
          new Teams(this, config.teamsWebhook).failure(
            "❌ ${params.TARGET_ENV.toUpperCase()} deploy FAILED. Initiate rollback runbook.\n${env.BUILD_URL}"
          )
        }
      }
      always { cleanWs notFailBuild: true }
    }
  }
}
