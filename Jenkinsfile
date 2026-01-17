pipeline {
  stages {

    stage ('git check out') {
      steps {
        checkout scm
      }
    }

    stage ('sonar analysys') {
      steps {
        sh '''
          sonar-scanner /
          Dsonar.projectkey=test_key /
          Dsonar.projectName=test_name /
          Dsonar.source=.
        
        '''
      }
    }
  }
}
