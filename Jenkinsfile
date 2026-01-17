pipeline {

  agent any
  
  stages {

    stage ('git check out') {
      steps {
        checkout scm
      }
    }

    stage ('sonar analysys') {
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
