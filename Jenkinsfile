pipeline {
    agent { label 'agent1' }

    environment {
        SN_INSTANCE = 'https://dev394841.service-now.com'
    }

    triggers {
        githubPush()
    }

    stages {

        // ================= COMMON =================
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Identify Branch') {
            steps {
                echo "Branch: ${env.BRANCH_NAME}"
                echo "PR ID: ${env.CHANGE_ID ?: 'N/A'}"
                echo "Source: ${env.CHANGE_BRANCH ?: 'N/A'}"
                echo "Target: ${env.CHANGE_TARGET ?: 'N/A'}"
            }
        }

        // ================= PR VALIDATION =================
        stage('PR Validation') {
            when { changeRequest() }

            stages {

                stage('Build Validation') {
                    steps {
                        sh 'mvn clean compile'
                    }
                }

                stage('Test') {
                    steps {
                        sh 'mvn test'
                    }
                }

                stage('Sonar Scan') {
                    steps {
                        withSonarQubeEnv('sonar-server') {
                            sh """
                                ${tool 'sonar_scanner'}/bin/sonar-scanner \
                                -Dsonar.projectKey=simple-webapp \
                                -Dsonar.projectName=simple-webapp \
                                -Dsonar.sources=.
                            """
                        }
                    }
                }

                stage('Quality Gate') {
                    steps {
                        timeout(time: 10, unit: 'MINUTES') {
                            waitForQualityGate abortPipeline: true
                        }
                    }
                }
            }
        }

        // ================= DEVELOPMENT =================
        stage('Development Pipeline') {
            when { branch 'develop' }

            stages {

                stage('Build') {
                    steps {
                        sh 'mvn clean package'
                    }
                }

                stage('Test') {
                    steps {
                        sh 'mvn test'
                    }
                }

                stage('Sonar Scan') {
                    steps {
                        withSonarQubeEnv('sonar-server') {
                            sh """
                                ${tool 'sonar_scanner'}/bin/sonar-scanner \
                                -Dsonar.projectKey=simple-webapp \
                                -Dsonar.projectName=simple-webapp \
                                -Dsonar.sources=.
                            """
                        }
                    }
                }

                stage('Quality Gate') {
                    steps {
                        timeout(time: 10, unit: 'MINUTES') {
                            waitForQualityGate abortPipeline: true
                        }
                    }
                }

                stage('Publish Artifacts') {
                    steps {
                        sh 'mvn deploy'
                    }
                }

                stage('Deploy to Dev Environment') {
                    steps {
                        echo 'Deploying to development environment...'
                        sh 'curl -f http://dev-environment/health'
                    }
                }
            }
        }

        // ================= RELEASE =================
        stage('Release Pipeline') {
            when {
                branch pattern: "release/.*", comparator: "REGEXP"
            }

            stages {

                stage('Build and Verify') {
                    steps {
                        sh 'mvn clean verify -Pqa-tests'
                    }
                }

                stage('Deploy to QA') {
                    steps {
                        echo 'Deploying to QA...'
                    }
                }

                stage('QA Health Check') {
                    steps {
                        sh 'curl -f http://qa-environment/health'
                    }
                }

                stage('DAST Scan') {
                    steps {
                        echo 'Running DAST scan...'
                    }
                }

                stage('Approval for UAT') {
                    steps {
                        timeout(time: 10, unit: 'MINUTES') {
                            input message: 'Approve deployment to UAT?', ok: 'Deploy'
                        }
                    }
                }

                stage('Deploy to UAT') {
                    steps {
                        echo 'Deploying to UAT...'
                    }
                }

                stage('UAT Health Check') {
                    steps {
                        sh 'curl -f http://uat-environment/health'
                    }
                }
            }
        }

        // ================= PRODUCTION =================
        stage('Production Pipeline') {
            when {
                allOf {
                    branch 'main'
                    not { changeRequest() }
                }
            }

            stages {

                stage('ServiceNow Approval Loop') {
                    steps {
                        script {
                            def approved = false

                            while (!approved) {

                                stage('Approval Input') {
                                    def userInput = input(
                                        message: 'Enter Change Number and Approve',
                                        ok: 'Approve',
                                        parameters: [
                                            string(name: 'CHANGE_NUMBER', defaultValue: '', description: 'Enter Change Number (e.g., CHG0030002)')
                                        ]
                                    )
                                    env.USER_CHANGE = userInput
                                    echo "Entered Change: ${env.USER_CHANGE}"
                                }

                                stage('Validate Change Approval') {
                                    withCredentials([usernamePassword(
                                        credentialsId: 'SERVICE_NOW_CRED',
                                        usernameVariable: 'user',
                                        passwordVariable: 'pass'
                                    )]) {

                                        def response = sh(
                                            script: """
                                                curl -s -k -u $user:$pass \
                                                "$SN_INSTANCE/api/now/table/change_request?sysparm_query=number=${env.USER_CHANGE}"
                                            """,
                                            returnStdout: true
                                        ).trim()

                                        echo "API Response: ${response}"

                                        def approval = response.split('"approval":"')[1].split('"')[0]
                                        echo "Approval Status: ${approval}"

                                        if (approval == "approved") {
                                            echo "Change Approved"
                                            approved = true
                                        } else {
                                            echo "Change not approved. Retry."
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Deploy to Production') {
                    steps {
                        echo 'Deploying to Production...'
                        sh 'curl -f http://prod-environment/health'
                    }
                }

                stage('Production Health Check') {
                    steps {
                        sh 'curl -f http://prod-environment/health'
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully'
        }
        failure {
            echo 'Pipeline failed'
        }
    }
}
