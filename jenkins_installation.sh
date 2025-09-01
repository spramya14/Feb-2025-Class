#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Update package list
sudo apt update -y

# Install OpenJDK 21
sudo apt install -y openjdk-21-jdk

# Add Jenkins repository and key to apt list
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package list and install Jenkins
sudo apt update -y
sudo apt install -y jenkins

# Add Jenkins user to sudoers without password prompt
JENKINS_USER="jenkins"
sudo usermod -aG sudo $JENKINS_USER
echo "$JENKINS_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$JENKINS_USER

# Configure Jenkins URL to avoid slow loading of jenkins when ec2 machine public_ip changes
cat << 'EOF' > "/home/ubuntu/jenkins_ip_url_update.sh"
#!/bin/bash
echo "<?xml version='1.1' encoding='UTF-8'?>
<jenkins.model.JenkinsLocationConfiguration>
  <jenkinsUrl>http://$(curl -s http://checkip.amazonaws.com):8080/</jenkinsUrl>
</jenkins.model.JenkinsLocationConfiguration> " | sudo tee /var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml
sudo systemctl restart jenkins
EOF

chmod +x "/home/ubuntu/jenkins_ip_url_update.sh"
# Restart Jenkins to apply configuration
sudo systemctl restart jenkins

# Add cron job to restart Jenkins daily at 2:30 AM
CRON_JOB="@reboot sudo bash /home/ubuntu/jenkins_ip_url_update.sh"
# Check if the cron job already exists, If not add the entry 

echo $CRON_JOB
# Initialize the crontab if it doesn't exist
crontab -u ubuntu -l 2>/dev/null > mycron || touch mycron

# Add your cron job
echo "$CRON_JOB" >> mycron

# Install the new crontab
crontab -u ubuntu mycron

# Clean up
rm mycron



