pipeline {
    agent { label 'build' }  // Make sure your Jenkins agent has this label

    environment {
        nexusurl = 'http://13.222.96.18:8081/repository/maven-releases/'
        groupid = 'com.example'
        artifactid = 'simple-webapp'
    }
    

    stages {

        stage('Git Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Maven Compile') {
            steps {
                // Compile and package in a single step
                sh 'mvn compile'
            }
        }

        stage('Maven Build') {
            steps {
                // Compile and package in a single step
                sh 'mvn clean package'
            }
        }

        stage('artifacts upload') {

          steps {

            withCredentials([string(credentialsId: 'sonar_credentials', variable: 'sonar_credentials')]) {
              sh '''
                mvn deploy:deploy-file \
                -DgroupId=${groupid} \
                -DartifactId=${artifactid} \
                -Durl=${nexusurl} \
                -Dfile=target/${artifactid}-1.0.war \
                -DrepositoryId=sonatype-nexus \
              '''
          }
        }
    }
  } 
}
