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

            withCredentials([usernamePassword(
                credentialsId: 'sonar_credentials', 
                usernameVariable: 'nexus_user', 
                passwordVariable: 'nexus_pass'
            )]) {
                sh """
                    mvn deploy:deploy-file \
                        -DgroupId=${groupid} \
                        -DartifactId=${artifactid} \
                        -Dversion=1.0 \
                        -Dpackaging=war \
                        -Dfile=target/${artifactid}-1.0.war \
                        -Durl=${nexusurl} \
                        -DrepositoryId=sonatype-nexus \
                        -Dusername=${nexus_user} \
                        -Dpassword=${nexus_pass} \
                        -DgeneratePom=true
                """
          }
        }
    }
  } 
}
