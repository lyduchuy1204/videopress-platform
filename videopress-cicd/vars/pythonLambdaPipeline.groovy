// vars/pythonLambdaPipeline.groovy
//
// Pipeline CI cho repo backend Python Lambda (videopress-backend).
// Lint + pytest + coverage + build zip + push artifact.
//
// Cách dùng (Jenkinsfile của repo consumer):
//
//   @Library('videopress-cicd@v1.2.0') _
//   pythonLambdaPipeline(
//     pythonVersion:     '3.11',
//     coverageThreshold: 70,
//     lambdas:           ['hello', 'auth-issue', 'video-create-job'],
//     artifactBucket:    'videopress-artifacts-non-prod',
//     teamsWebhook:      env.TEAMS_WEBHOOK_BACKEND
//   )

import com.videopress.notify.Teams

/**
 * Pipeline CI cho repo Python Lambda.
 *
 * @param config Map cấu hình:
 *   - pythonVersion     {String}  Phiên bản Python, ví dụ '3.11'.
 *   - coverageThreshold {Integer} % coverage tối thiểu để pipeline pass (default 70).
 *   - lambdas           {List}    Danh sách tên lambda để build zip riêng từng cái.
 *   - artifactBucket    {String}  S3 bucket lưu zip output.
 *   - teamsWebhook      {String}  Credential ID của Teams webhook (Jenkins Secret text).
 */
def call(Map config) {
  // ---- Validate parameter ---------------------------------------------------
  assert config.pythonVersion     : "pythonLambdaPipeline: missing 'pythonVersion'"
  assert config.lambdas           : "pythonLambdaPipeline: missing 'lambdas' (List)"
  assert config.artifactBucket    : "pythonLambdaPipeline: missing 'artifactBucket'"
  assert config.teamsWebhook      : "pythonLambdaPipeline: missing 'teamsWebhook' (credential ID)"
  config.coverageThreshold = (config.coverageThreshold ?: 70) as Integer

  pipeline {
    agent any

    options {
      timeout(time: 30, unit: 'MINUTES')
      timestamps()
      buildDiscarder(logRotator(numToKeepStr: '50'))
    }

    environment {
      PYTHON_VERSION = "${config.pythonVersion}"
      ARTIFACT_BUCKET = "${config.artifactBucket}"
      COVERAGE_MIN = "${config.coverageThreshold}"
    }

    stages {
      stage('Checkout') {
        steps { checkout scm }
      }

      stage('Setup Python') {
        steps {
          sh '''
            python${PYTHON_VERSION} -m venv .venv
            . .venv/bin/activate
            pip install --upgrade pip
            pip install -r requirements-dev.txt
          '''
        }
      }

      stage('Lint + Format') {
        steps {
          sh '. .venv/bin/activate && black --check .'
          sh '. .venv/bin/activate && pylint $(git ls-files "*.py") --fail-under=8.0'
        }
      }

      stage('Test + Coverage') {
        steps {
          sh '. .venv/bin/activate && pytest --cov=src --cov-report=xml --cov-report=html --cov-fail-under=${COVERAGE_MIN}'
        }
        post {
          always {
            publishHTML target: [
              reportDir: 'htmlcov', reportFiles: 'index.html',
              reportName: 'pytest-cov', keepAll: true, allowMissing: true
            ]
          }
        }
      }

      stage('Type Check') {
        steps {
          sh '. .venv/bin/activate && mypy src/ --ignore-missing-imports'
        }
      }

      stage('Package per Lambda') {
        steps {
          script {
            config.lambdas.each { lambdaName ->
              sh "./scripts/package-lambda.sh ${lambdaName} build/${lambdaName}-${env.GIT_COMMIT}.zip"
            }
          }
        }
      }

      stage('Upload Artifacts') {
        steps {
          script {
            // Dùng OIDC role assume; KHÔNG hardcode access key.
            withCredentials([string(credentialsId: 'aws-oidc-non-prod-role', variable: 'AWS_ROLE_ARN')]) {
              try {
                config.lambdas.each { lambdaName ->
                  sh """
                    aws s3 cp build/${lambdaName}-${env.GIT_COMMIT}.zip \
                      s3://${env.ARTIFACT_BUCKET}/${lambdaName}/${env.GIT_COMMIT}.zip \
                      --metadata commit=${env.GIT_COMMIT},branch=${env.BRANCH_NAME}
                  """
                }
              } finally {
                // Cleanup credential file local (defense-in-depth).
                sh 'rm -f /tmp/aws-credentials || true'
              }
            }
          }
        }
      }
    }

    post {
      success {
        script {
          new Teams(this, config.teamsWebhook).success(
            "✅ Backend CI passed: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
          )
        }
      }
      failure {
        script {
          new Teams(this, config.teamsWebhook).failure(
            "❌ Backend CI FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}\n${env.BUILD_URL}"
          )
        }
      }
      always { cleanWs notFailBuild: true }
    }
  }
}
