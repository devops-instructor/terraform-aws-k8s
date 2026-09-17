pipeline {
    agent any
    options {
        ansiColor('xterm')
    }
    parameters {
        choice(
            name: 'action',
            choices: ['select', 'apply', 'destroy'],
            description: 'Terraform action'
        )
    }
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        AWS_REGION            = 'us-west-2'
    }
    stages {

        stage('Terraform Init') {
            agent {
                docker {
                    image 'hashicorp/terraform:1.16.0'
                    args '--entrypoint=""'
                    reuseNode true
                }
            }
            steps {
                sh 'terraform init'
            }
        }
        stage('Terraform Apply') {
            when {
                expression { params.action == 'apply' }
            }
            agent {
                docker {
                    image 'hashicorp/terraform:1.16.0'
                    args '--entrypoint=""'
                    reuseNode true
                }
            }
            steps {
                sh 'terraform apply -auto-approve'
                sh 'cat inventory.ini'
            }
        }
        stage('Ansible - Install K3s') {
            when {
                expression { params.action == 'apply' }
            }
            agent {
                docker {
                    image 'alpine/ansible:2.21.0'
                    args '-u root:root'
                    reuseNode true
                }
            }
            environment {
                ANSIBLE_HOST_KEY_CHECKING = 'False'
            }
            steps {
                sshagent(credentials: ['k8s-keypair']) {
                    sh 'ansible-playbook -i inventory.ini site-k8s.yml'
                }
            }
        }
        stage('Terraform Destroy') {
            when {
                expression { params.action == 'destroy' }
            }
            agent {
                docker {
                    image 'hashicorp/terraform:1.16.0'
                    args '--entrypoint=""'
                    reuseNode true
                }
            }
            steps {
                sh 'terraform destroy -auto-approve'
            }
        }
    }
}