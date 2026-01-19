pipeline {
    agent { label 'build' }  // Make sure your Jenkins agent has this label
    customWorkspace '/home/jenkins/workspace'

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
    }
}
