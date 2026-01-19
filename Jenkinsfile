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

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') { // Replace with your SonarQube server name
                    sh "mvn sonar:sonar -Dsonar.projectKey=test_key -Dsonar.projectName=test_name"
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
