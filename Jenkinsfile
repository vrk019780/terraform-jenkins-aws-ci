// Jenkinsfile for Terraform CI/CD Pipeline
pipeline {
    // Agent defines where the pipeline will run.
    // 'any' means it can run on any available agent (including the Jenkins master).
    // For production, you might use 'agent { label 'your-agent-label' }'
    agent any

    // Environment variables that can be used throughout the pipeline
    environment {
        // Define the Terraform version to install
        TERRAFORM_VERSION = "1.8.5" // Always check HashiCorp releases for the latest stable version!
        // AWS credentials (if not using IAM Role for EC2 instance)
        // IMPORTANT: NEVER hardcode AWS credentials here. Use Jenkins Credentials!
        // AWS_ACCESS_KEY_ID = credentials('your-aws-access-key-id-credential-id')
        // AWS_SECRET_ACCESS_KEY = credentials('your-aws-secret-access-key-credential-id')
        // AWS_REGION = "us-east-1" // Set your desired AWS region
    }

    stages {
        // Stage to install Terraform on the Jenkins agent
        stage('Install Terraform') {
            steps {
                script {
                    // Check if Terraform is already in PATH and is the correct version
                    // This avoids re-downloading on every run if already present
                    def tfPath = sh(returnStdout: true, script: 'which terraform || true').trim()
                    def installedVersion = ""
                    if (tfPath != "") {
                        installedVersion = sh(returnStdout: true, script: 'terraform version | head -n 1 | cut -d " " -f 2 | tr -d "v" || true').trim()
                    }

                    if (installedVersion != env.TERRAFORM_VERSION) {
                        echo "Terraform v${env.TERRAFORM_VERSION} not found or version mismatch. Installing..."
                        sh """
                            #!/bin/bash
                            # Clean up any previous Terraform installations in the workspace
                            rm -f /usr/local/bin/terraform # Remove global symlink if exists
                            rm -f \${WORKSPACE}/terraform # Remove local binary if exists

                            TERRAFORM_ZIP="terraform_${env.TERRAFORM_VERSION}_linux_amd64.zip"
                            TERRAFORM_URL="https://releases.hashicorp.com/terraform/${env.TERRAFORM_VERSION}/${TERRAFORM_ZIP}"

                            echo "Downloading Terraform v${env.TERRAFORM_VERSION}..."
                            curl -LO \${TERRAFORM_URL}

                            echo "Unzipping Terraform..."
                            unzip -o \${TERRAFORM_ZIP} -d \${WORKSPACE}/

                            echo "Cleaning up..."
                            rm \${TERRAFORM_ZIP}

                            # Make the downloaded Terraform binary executable and add to PATH for this build
                            chmod +x \${WORKSPACE}/terraform
                            export PATH=\${WORKSPACE}:\${PATH}
                            echo "PATH is: \${PATH}"

                            echo "Verifying Terraform installation..."
                            terraform version
                        """
                    } else {
                        echo "Terraform v${env.TERRAFORM_VERSION} is already installed."
                    }
                }
            }
        }

        // Stage to initialize Terraform working directory
        stage('Terraform Init') {
            steps {
                script {
                    // Ensure Terraform binary is in PATH for this stage
                    sh 'export PATH=${WORKSPACE}:${PATH}'
                    echo "Initializing Terraform modules..."
                    sh 'terraform init'
                }
            }
        }

        // Stage to validate Terraform code syntax
        stage('Terraform Validate') {
            steps {
                script {
                    sh 'export PATH=${WORKSPACE}:${PATH}'
                    echo "Validating Terraform code..."
                    sh 'terraform validate'
                }
            }
        }

        // Stage to generate and show a Terraform plan
        stage('Terraform Plan') {
            steps {
                script {
                    sh 'export PATH=${WORKSPACE}:${PATH}'
                    echo "Generating Terraform plan..."
                    sh 'terraform plan -out=tfplan'
                    // Optionally, show the plan output in the console
                    sh 'terraform show tfplan'
                }
            }
        }

        // Optional: Stage for manual approval before applying changes
        // Uncomment this stage if you want to review the plan before deployment
        /*
        stage('Manual Approval for Apply') {
            steps {
                input message: 'Proceed with Terraform Apply?', ok: 'Deploy'
            }
        }
        */

        // Optional: Stage to apply Terraform changes
        // CAUTION: This will make changes to your AWS account.
        // For a CI-only pipeline, you might remove or comment out this stage.
        // For full Continuous Deployment, uncomment this.
        /*
        stage('Terraform Apply') {
            steps {
                script {
                    sh 'export PATH=${WORKSPACE}:${PATH}'
                    echo "Applying Terraform changes..."
                    sh 'terraform apply -auto-approve=true tfplan'
                }
            }
        }
        */
    }

    // Post-build actions (e.g., clean up workspace, report status)
    post {
        always {
            echo "Pipeline finished. Cleaning up workspace..."
            // cleanWs() // Uncomment to clean workspace after every build
        }
        success {
            echo "Pipeline succeeded!"
            // You can add steps here to report success status to GitHub
            // For example, using the GitHub plugin's functionality:
            // githubNotify context: 'ci/jenkins/terraform', state: 'SUCCESS', description: 'Terraform pipeline succeeded'
        }
        failure {
            echo "Pipeline failed!"
            // githubNotify context: 'ci/jenkins/terraform', state: 'FAILURE', description: 'Terraform pipeline failed'
        }
    }
}
