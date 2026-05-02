pipeline {
    agent { label 'agent1' }

    environment {
        SN_INSTANCE = 'https://dev394841.service-now.com'
    }

    triggers {
        githubPush()
    }

    stages {

        // ================= COMMON ==================
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
        stage('PR Validation - Build') {
            when { changeRequest() }
            steps {
                sh 'mvn clean compile'
            }
        }

        stage('PR Validation - Test') {
            when { changeRequest() }
            steps {
                sh 'mvn test'
            }
        }

        stage('PR Validation - Sonar Scan') {
            when { changeRequest() }
            steps {
                withSonarQubeEnv('sonar_server') {
                    script {
                        def scannerHome = tool 'sonar-scanner'
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=simple-webapp \
                            -Dsonar.projectName=simple-webapp \
                            -Dsonar.sources=.
                        """
                    }
                }
            }
        }

        stage('PR Quality Gate') {
            when { changeRequest() }
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        // ================= DEVELOPMENT =================
        stage('Development Build') {
            when { branch 'develop' }
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Development Test') {
            when { branch 'develop' }
            steps {
                sh 'mvn test'
            }
        }

        stage('Development Sonar Scan') {
            when { branch 'develop' }
            steps {
                withSonarQubeEnv('sonar_server') {
                    script {
                        def scannerHome = tool 'sonar-scanner'
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=simple-webapp \
                            -Dsonar.projectName=simple-webapp \
                            -Dsonar.sources=.
                        """
                    }
                }
            }
        }

        stage('Development Quality Gate') {
            when { branch 'develop' }
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Publish Artifacts') {
            when { branch 'develop' }
            steps {
                sh 'mvn deploy'
            }
        }

        stage('Deploy to Dev Environment') {
            when { branch 'develop' }
            steps {
                echo 'Deploying to development environment...'
                sh 'curl -f http://dev-environment/health'
            }
        }

        // ================= RELEASE =================
        stage('Release Build & Verify') {
            when {
                branch pattern: "release/.*", comparator: "REGEXP"
            }
            steps {
                sh 'mvn clean verify -Pqa-tests'
            }
        }

        stage('Deploy to QA') {
            when {
                branch pattern: "release/.*", comparator: "REGEXP"
            }
            steps {
                echo 'Deploying to QA...'
            }
        }

        stage('QA Health Check') {
            when {
                branch pattern: "release/.*", comparator: "REGEXP"
            }
            steps {
                sh 'curl -f http://qa-environment/health'
            }
        }

        stage('DAST Scan') {
            when {
                branch pattern: "release/.*", comparator: "REGEXP"
            }
            steps {
                echo 'Running DAST scan...'
            }
        }

        stage('UAT Approval') {
            when {
                branch pattern: "release/.*", comparator: "REGEXP"
            }
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    input message: 'Approve deployment to UAT?', ok: 'Deploy'
                }
            }
        }

        stage('Deploy to UAT') {
            when {
                branch pattern: "release/.*", comparator: "REGEXP"
            }
            steps {
                echo 'Deploying to UAT...'
            }
        }

        stage('UAT Health Check') {
            when {
                branch pattern: "release/.*", comparator: "REGEXP"
            }
            steps {
                sh 'curl -f http://uat-environment/health'
            }
        }

        // ================= PRODUCTION =================
        stage('Production Approval Loop') {
            when {
                allOf {
                    branch 'main'
                    not { changeRequest() }
                }
            }
            steps {
                script {
                    def approved = false

                    while (!approved) {

                        def userInput = input(
                            message: 'Enter Change Number and Approve',
                            ok: 'Approve',
                            parameters: [
                                string(name: 'CHANGE_NUMBER', defaultValue: '', description: 'Enter Change Number')
                            ]
                        )

                        env.USER_CHANGE = userInput

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

                            echo "Response: ${response}"

                            if (response.contains('"approval":"approved"')) {
                                echo "Change Approved"
                                approved = true
                            } else {
                                echo "Not approved yet. Retry..."
                            }
                        }
                    }
                }
            }
        }

        stage(Promote Artifacts to Nexus-release Repo){
            when {
                allOf {
                    branch 'main'
                    not { changeRequest() }
                }
            }
            steps{
                chmod +x deploy-prod.sh
                sh './deploy-prod.sh'
            }
        }
        stage('Get Latest Artifact Name') {
            when {
                allOf {
                    branch 'main'
                    not { changeRequest() }
                }
            }
            steps {
                script {
        
                    ARTIFACT = sh(
                        script: """
                        curl -s -u "$NEXUS_USER:$NEXUS_PASS" \
                        "$NEXUS_URL/service/rest/v1/search/assets?repository=maven-releases&name=app" \
                        | jq -r '.items[].path' \
                        | grep ".war" \
                        | sort -V \
                        | tail -1 \
                        | awk -F'/' '{print \$NF}'
                        """,
                        returnStdout: true
                    ).trim()
        
                    if (!ARTIFACT) {
                        error "No WAR found in Nexus!"
                    }
        
                    echo "Latest Artifact: ${ARTIFACT}"
                }
            }
        }

        stage('Deploy to Production') {
            when {
                allOf {
                    branch 'main'
                    not { changeRequest() }
                }
            }
            steps {
                sh """
                echo 'Deploying to Production...'
                
                # download from Nexus release repo
                curl -f -u "$NEXUS_USER:$NEXUS_PASS" -O \
                "$NEXUS_URL/repository/maven-releases/com/company/app/${ARTIFACT}"

                chmod +x deploy-prod.sh
                ./deploy-prod.sh ${ARTIFACT}
                
                """                
            }
        }

        stage('Production Health Check') {
            when {
                allOf {
                    branch 'main'
                    not { changeRequest() }
                }
            }
            steps {
                sh 'curl -f http://prod-environment/health'
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
