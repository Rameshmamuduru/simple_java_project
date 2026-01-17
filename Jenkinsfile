pipeline {

    agent any

    tools {
        mavn 'maven'
    }

    stages {

        stage('Git Checkout') {
            steps {
                checkout scm
            }
        }

        stage ('maven compile') {
            steps {

                sh 'mvn compile'
            }
        }

          stage ('maven build') {
            steps {

                sh 'mvn clean package'
            }
        }

        stage('Sonar Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    script {
                        def scannerHome = tool 'sonar-scanner'
                        sh """
                        ${scannerHome}/bin/sonar-scanner \
                          -Dsonar.projectKey=test_key \
                          -Dsonar.projectName=test_name \
                          -Dsonar.sources=.
                        """
                    }
                }
            }
        }
    }
}
