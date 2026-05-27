// vars/smokeTestPipeline.groovy
//
// Chạy Postman collection / curl test sau deploy để xác nhận hệ thống chạy cơ bản.
// Có thể trigger từ stage cuối của terraformDeployPipeline hoặc rerun độc lập.
//
// Cách dùng:
//
//   @Library('videopress-cicd@v1.2.0') _
//   smokeTestPipeline(
//     targetEnv:            'uat',
//     apiInvokeUrl:         'https://api-uat.videopress.example.com',
//     postmanCollectionPath: 'tests/smoke.postman_collection.json',
//     expectedHttpCodes:    [200, 201, 204],
//     teamsWebhook:         'teams-webhook-deploy'
//   )

import com.videopress.notify.Teams

/**
 * Pipeline smoke test sau deploy.
 *
 * @param config Map:
 *   - targetEnv             {String}      uat|staging|prod.
 *   - apiInvokeUrl          {String}      Base URL API.
 *   - postmanCollectionPath {String}      Đường dẫn collection trong workspace.
 *   - expectedHttpCodes     {List<Integer>}
 *   - teamsWebhook          {String}      Credential ID.
 */
def call(Map config) {
  assert config.targetEnv             : "smokeTestPipeline: missing 'targetEnv'"
  assert config.apiInvokeUrl          : "smokeTestPipeline: missing 'apiInvokeUrl'"
  assert config.postmanCollectionPath : "smokeTestPipeline: missing 'postmanCollectionPath'"
  assert config.teamsWebhook          : "smokeTestPipeline: missing 'teamsWebhook'"
  config.expectedHttpCodes = config.expectedHttpCodes ?: [200, 201, 204]

  pipeline {
    agent any

    options {
      timeout(time: 15, unit: 'MINUTES')
      timestamps()
    }

    environment {
      TARGET_ENV   = "${config.targetEnv}"
      API_BASE_URL = "${config.apiInvokeUrl}"
    }

    stages {

      stage('Checkout') { steps { checkout scm } }

      stage('Install newman') {
        steps {
          sh '''
            node --version
            npm --version
            npm install -g newman newman-reporter-htmlextra
          '''
        }
      }

      stage('Run Postman collection') {
        steps {
          sh """
            newman run ${config.postmanCollectionPath} \
              --env-var base_url=${env.API_BASE_URL} \
              --reporters cli,htmlextra,junit \
              --reporter-htmlextra-export newman-report.html \
              --reporter-junit-export newman-junit.xml \
              --bail
          """
        }
        post {
          always {
            junit allowEmptyResults: true, testResults: 'newman-junit.xml'
            publishHTML target: [
              reportDir: '.', reportFiles: 'newman-report.html',
              reportName: 'Newman Smoke Test', keepAll: true, allowMissing: true
            ]
          }
        }
      }

      stage('Parse result — fail nếu critical fail') {
        steps {
          script {
            // Parse junit XML, fail nếu có test name chứa "[critical]" mà fail.
            def report = readFile('newman-junit.xml')
            if (report =~ /(?s)<testcase[^>]*name="[^"]*\[critical\][^"]*"[^>]*>\s*<failure/) {
              error("Smoke test có CRITICAL endpoint fail. Block promotion / trigger rollback.")
            }
          }
        }
      }
    }

    post {
      success {
        script {
          new Teams(this, config.teamsWebhook).success(
            "✅ Smoke test OK: ${env.TARGET_ENV} (#${env.BUILD_NUMBER})"
          )
        }
      }
      failure {
        script {
          new Teams(this, config.teamsWebhook).failure(
            "❌ Smoke test FAILED: ${env.TARGET_ENV}\n${env.BUILD_URL}"
          )
        }
      }
      always { cleanWs notFailBuild: true }
    }
  }
}
