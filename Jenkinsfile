pipeline {

    agent any

    tools {
        sonarScanner 'sonar-scanner'
    }

    stages {

        stage('Git Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Sonar Analysis') {
            steps {
                withSonarQubeEnv('sonar-prod') {
                    sh '''
                    sonar-scanner \
                      -Dsonar.projectKey=test_key \
                      -Dsonar.projectName=test_name \
                      -Dsonar.sources=.
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }
}
