// Optional: the same CI as GitHub Actions, for a Jenkins server.
// The agent needs docker, trivy, gitleaks, python3 and the AWS CLI, plus an IAM role allowed to push to ECR.
pipeline {
  agent any
  environment {
    AWS_REGION = 'eu-north-1'
    REGISTRY   = "${env.AWS_ACCOUNT_ID}.dkr.ecr.eu-north-1.amazonaws.com"
  }
  stages {
    stage('Unit tests') {
      steps {
        dir('apps/api') {
          sh 'python3 -m venv .venv && . .venv/bin/activate && pip install -q -r requirements-dev.txt && pytest -q'
        }
      }
    }
    stage('Secret scan') {
      steps { sh 'gitleaks detect --source . --no-banner' }
    }
    stage('Build and scan images') {
      steps {
        script {
          for (svc in ['api', 'worker', 'frontend']) {
            sh "docker build -t shop-${svc}:${GIT_COMMIT} apps/${svc}"
            sh "trivy image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 shop-${svc}:${GIT_COMMIT}"
          }
        }
      }
    }
    stage('Push to ECR') {
      when { branch 'main' }
      steps {
        sh 'aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REGISTRY'
        script {
          for (svc in ['api', 'worker', 'frontend']) {
            sh "docker tag shop-${svc}:${GIT_COMMIT} ${REGISTRY}/shop-${svc}:${GIT_COMMIT}"
            sh "docker push ${REGISTRY}/shop-${svc}:${GIT_COMMIT}"
          }
        }
      }
    }
  }
}
