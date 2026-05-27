// vars/terraformRollbackPipeline.groovy
//
// Emergency rollback pipeline. CHỈ trigger MANUAL từ Jenkins UI.
// Khôi phục state Terraform về version cũ từ S3 versioning, có 2 approval gate.
//
// Cách dùng:
//
//   @Library('videopress-cicd@v1.2.0') _
//   terraformRollbackPipeline(
//     allowedEnvs:           ['staging', 'prod'],
//     stateArchiveBucket:    'videopress-state-archive',
//     stateBucketOf:         [staging: 'videopress-tfstate-staging', prod: 'videopress-tfstate-prod'],
//     workdirOf:             [staging: 'envs/staging', prod: 'envs/prod'],
//     awsRoleArnOf:          [staging: env.AWS_OIDC_STG, prod: env.AWS_OIDC_PROD],
//     requireDoubleApproval: true,
//     auditBucket:           'videopress-audit-trail',
//     teamsWebhook:          'teams-webhook-incident'
//   )

import com.videopress.aws.AssumeRole
import com.videopress.aws.S3StateBackup
import com.videopress.notify.Teams

/**
 * Pipeline emergency rollback.
 *
 * @param config Map:
 *   - allowedEnvs           {List<String>}
 *   - stateArchiveBucket    {String}
 *   - stateBucketOf         {Map<env,String>} Bucket gốc lưu tfstate per env.
 *   - workdirOf             {Map<env,String>}
 *   - awsRoleArnOf          {Map<env,String>}
 *   - requireDoubleApproval {Boolean} Default true.
 *   - auditBucket           {String}
 *   - teamsWebhook          {String}
 */
def call(Map config) {
  assert config.allowedEnvs        : "terraformRollbackPipeline: missing 'allowedEnvs'"
  assert config.stateArchiveBucket : "terraformRollbackPipeline: missing 'stateArchiveBucket'"
  assert config.stateBucketOf      : "terraformRollbackPipeline: missing 'stateBucketOf'"
  assert config.workdirOf          : "terraformRollbackPipeline: missing 'workdirOf'"
  assert config.awsRoleArnOf       : "terraformRollbackPipeline: missing 'awsRoleArnOf'"
  assert config.auditBucket        : "terraformRollbackPipeline: missing 'auditBucket'"
  assert config.teamsWebhook       : "terraformRollbackPipeline: missing 'teamsWebhook'"
  config.requireDoubleApproval = (config.requireDoubleApproval == null) ? true : config.requireDoubleApproval

  pipeline {
    agent any

    options {
      timeout(time: 120, unit: 'MINUTES')
      timestamps()
      buildDiscarder(logRotator(numToKeepStr: '200'))   // giữ lâu cho audit
    }

    parameters {
      choice(name: 'TARGET_ENV', choices: config.allowedEnvs, description: 'Env cần rollback')
      string(name: 'TARGET_STATE_VERSION_ID', defaultValue: '', description: 'S3 versionId của tfstate cần khôi phục (lấy từ stage List versions)')
      text(name: 'REASON', defaultValue: '', description: 'Lý do rollback (BẮT BUỘC, vào audit log)')
      string(name: 'INCIDENT_TICKET', defaultValue: '', description: 'Link Jira / PagerDuty incident')
      booleanParam(name: 'RESTORE_DYNAMODB_PITR', defaultValue: false, description: 'Có restore DynamoDB từ PITR không?')
    }

    stages {

      stage('Validate input') {
        steps {
          script {
            assert params.REASON?.trim()          : "REASON là BẮT BUỘC để vào audit log."
            assert params.INCIDENT_TICKET?.trim() : "INCIDENT_TICKET là BẮT BUỘC."
            echo "Rollback ${params.TARGET_ENV} | reason: ${params.REASON} | ticket: ${params.INCIDENT_TICKET}"
          }
        }
      }

      stage('Approval — Trước khi tải state cũ') {
        steps {
          script {
            timeout(time: 30, unit: 'MINUTES') {
              def approver = input(
                message: "ROLLBACK ${params.TARGET_ENV.toUpperCase()} — Approval 1/2",
                submitter: 'sre-oncall,engineering-managers',
                submitterParameter: 'APPROVER_1'
              )
              env.APPROVER_1 = approver
            }
          }
        }
      }

      stage('Checkout & List state versions') {
        steps {
          checkout scm
          script {
            def env_ = params.TARGET_ENV
            new AssumeRole(this).withOidc(config.awsRoleArnOf[env_]) {
              sh """
                aws s3api list-object-versions \
                  --bucket ${config.stateBucketOf[env_]} \
                  --prefix ${env_}/terraform.tfstate \
                  --max-items 10 \
                  --output table
              """
            }
          }
        }
      }

      stage('Backup current state') {
        steps {
          script {
            def env_ = params.TARGET_ENV
            new S3StateBackup(this).backupBeforeApply(
              config.stateBucketOf[env_],
              "${env_}/terraform.tfstate",
              config.stateArchiveBucket
            )
          }
        }
      }

      stage('Download old state version') {
        steps {
          script {
            def env_ = params.TARGET_ENV
            new AssumeRole(this).withOidc(config.awsRoleArnOf[env_]) {
              dir(config.workdirOf[env_]) {
                sh """
                  aws s3api get-object \
                    --bucket ${config.stateBucketOf[env_]} \
                    --key ${env_}/terraform.tfstate \
                    --version-id ${params.TARGET_STATE_VERSION_ID} \
                    terraform.tfstate
                """
              }
            }
          }
        }
      }

      stage('Init + Plan (verify diff)') {
        steps {
          script {
            def env_ = params.TARGET_ENV
            new AssumeRole(this).withOidc(config.awsRoleArnOf[env_]) {
              dir(config.workdirOf[env_]) {
                sh 'terraform init -reconfigure -input=false'
                sh 'terraform plan -out=tfplan.bin'
                sh 'terraform show -no-color tfplan.bin > plan-readable.txt'
                archiveArtifacts artifacts: 'plan-readable.txt,tfplan.bin', fingerprint: true
              }
            }
          }
        }
      }

      stage('Approval — Đọc plan rồi quyết') {
        when { expression { config.requireDoubleApproval } }
        steps {
          script {
            timeout(time: 60, unit: 'MINUTES') {
              def approver = input(
                message: "ROLLBACK ${params.TARGET_ENV.toUpperCase()} — Approval 2/2 (đọc plan-readable.txt)",
                submitter: 'sre-oncall,engineering-managers',
                submitterParameter: 'APPROVER_2'
              )
              env.APPROVER_2 = approver
            }
          }
        }
      }

      stage('Apply rollback') {
        steps {
          script {
            def env_ = params.TARGET_ENV
            lock(resource: "${env_}-rollback", inversePrecedence: true) {
              new AssumeRole(this).withOidc(config.awsRoleArnOf[env_]) {
                dir(config.workdirOf[env_]) {
                  sh 'terraform apply -input=false tfplan.bin'
                }
              }
            }
          }
        }
      }

      stage('Restore DynamoDB PITR (optional)') {
        when { expression { params.RESTORE_DYNAMODB_PITR } }
        steps {
          script {
            echo "⚠️ Restore DynamoDB từ PITR đòi hỏi xác nhận thủ công + tên table cụ thể. Xem on-call-runbook.md."
            input message: "Đã chuẩn bị tham số restore PITR? (xem runbook)", submitter: 'sre-oncall'
            // SRE chạy lệnh aws dynamodb restore-table-to-point-in-time thủ công
            // hoặc qua Jenkinsfile.dynamodb-pitr-restore (bonus pipeline).
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

      stage('Audit log') {
        steps {
          script {
            def auditEntry = [
              timestamp:        new Date().toString(),
              env:              params.TARGET_ENV,
              stateVersionId:   params.TARGET_STATE_VERSION_ID,
              reason:           params.REASON,
              incidentTicket:   params.INCIDENT_TICKET,
              approver1:        env.APPROVER_1,
              approver2:        env.APPROVER_2,
              buildUrl:         env.BUILD_URL
            ]
            writeFile file: 'audit.json', text: groovy.json.JsonOutput.prettyPrint(groovy.json.JsonOutput.toJson(auditEntry))
            sh "aws s3 cp audit.json s3://${config.auditBucket}/rollbacks/${params.TARGET_ENV}/${env.BUILD_ID}.json"
          }
        }
      }
    }

    post {
      success {
        script {
          new Teams(this, config.teamsWebhook).warning(
            "🔄 ROLLBACK ${params.TARGET_ENV.toUpperCase()} completed by ${env.APPROVER_1}+${env.APPROVER_2}\nIncident: ${params.INCIDENT_TICKET}"
          )
        }
      }
      failure {
        script {
          new Teams(this, config.teamsWebhook).failure(
            "🚨 ROLLBACK ${params.TARGET_ENV.toUpperCase()} FAILED. Vào AWS Console kiểm tra thủ công NGAY.\n${env.BUILD_URL}"
          )
        }
      }
      always { cleanWs notFailBuild: true }
    }
  }
}
