pipeline {
    agent { label 'build' }  // Make sure your Jenkins agent has this label

    stages {

        stage('Git Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Maven Build') {
            steps {
                // Compile and package in a single step
                sh 'mvn clean package'
            }
        }

        stage('Sonar Analysis') { 
            steps { 
                withSonarQubeEnv('sonar-server') { 
                    script { 
                        def scannerHome = tool 'sonar-scanner' 
                        sh """ ${scannerHome}/bin/sonar-scanner \ 
                        -Dsonar.projectKey=test_key \ 
                        -Dsonar.projectName=test_name \ 
                        -Dsonar.sources=. """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                // Wait for SonarQube Quality Gate result
                timeout(time: 15, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }
}
