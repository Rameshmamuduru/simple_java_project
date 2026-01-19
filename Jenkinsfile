pipeline {
    agent { label 'build' }  // Jenkins agent with Maven and Java

    environment {
        NEXUS_URL = 'http://13.222.96.18:8081/repository/maven-releases/'
        GROUP_ID  = 'com.example'
        ARTIFACT_ID = 'simple-webapp'
        VERSION = '1.0'
    }

    stages {

        stage('Git Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Maven Compile') {
            steps {
                sh 'mvn clean compile'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh "mvn sonar:sonar -Dsonar.projectKey=${ARTIFACT_ID} -Dsonar.projectName=${ARTIFACT_ID}"
                }
            }
        }

        stage('Maven Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Upload Artifact to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus_credentials',  // Make sure this is a Nexus username/password credential
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh """
                        mvn deploy:deploy-file \
                            -DgroupId=${GROUP_ID} \
                            -DartifactId=${ARTIFACT_ID} \
                            -Dversion=${VERSION} \
                            -Dpackaging=war \
                            -Dfile=target/${ARTIFACT_ID}-${VERSION}.war \
                            -Durl=${NEXUS_URL} \
                            -DrepositoryId=nexus-releases \
                            -Dusername=${NEXUS_USER} \
                            -Dpassword=${NEXUS_PASS} \
                            -DgeneratePom=true
                    """
                }
            }
        }

    }

    post {
        always {
            archiveArtifacts artifacts: "target/${ARTIFACT_ID}-${VERSION}.war", allowEmptyArchive: true
            cleanWs()
        }
    }
}
