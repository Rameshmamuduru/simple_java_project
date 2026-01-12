pipeline {
    agent {
        label 'build_node_1'
    }

    environment {
        app_name = 'simple-webapp-1.0'
        tomcat_dir = '/opt/tomcat'
        ssh_user = 'tomcat'
        tomcat_host = '100.31.127.16'
    }

    stages {

        stage('Check Agent') {
            steps {
                sh 'hostname'
                sh 'java -version'
            }
        }

        stage('Git Checkout') {
            steps {
                git url: 'https://github.com/Rameshmamuduru/simple_java_project.git',
                    branch: 'main'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('copy WAR to tomcat server') {
            steps {
                 // Generate timestamp in Groovy
                script {
                    env.time_stamp = new Date().format("yyyy-MM-dd-HH-mm-ss")
                }
                sh """
                    set -e
                    echo "Copying WAR file to Tomcat server..."
                    rsync -avz --progress \
                        /home/jenkins/workspace/java_maven/target/${app_name}.war \
                        ${ssh_user}@${tomcat_host}:${tomcat_dir}/releases/${app_name}-${BUILD_NUMBER}.war
                    echo "WAR copied successfully!"
                """
            }
        }

        stage('Deploy to PROD') {
            steps {
                 // Ensure TIME_STAMP is defined in a previous step or here
        script {
            env.TIME_STAMP = new Date().format("yyyy-MM-dd-HH-mm-ss")
        }
        sh """
            ssh ${ssh_user}@${tomcat_host} '
                set -e
                echo "Stopping Tomcat..."
                sudo systemctl stop tomcat

                # Backup existing WAR if it exists
                if [ -f ${tomcat_dir}/webapps/${app_name}.war ]; then
                    echo "Backing up existing WAR..."
                    cp ${tomcat_dir}/webapps/${app_name}.war ${tomcat_dir}/backup/${app_name}-${TIME_STAMP}.war
                fi

                # Link the new WAR
                echo "Deploying new WAR..."
                ln -sfn ${tomcat_dir}/releases/${app_name}-${BUILD_NUMBER}.war ${tomcat_dir}/webapps/${app_name}.war

                echo "Starting Tomcat..."
                sudo systemctl start tomcat
                echo "Deployment complete."
                    '
                """
            }
        }
    }
}
