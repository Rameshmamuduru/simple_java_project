# Full Deployment Guide:

## Launch EC2 and setup jenkins
```
sudo apt update
sudo apt install fontconfig openjdk-21-jre
java -version
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install jenkins
```
<img width="1365" height="674" alt="image" src="https://github.com/user-attachments/assets/a382cb32-6541-4601-8bd7-cc951a6a7d3d" />

## Launch EC2 and setup SonarQube,trivy,Nexus
```
sudo apt update
sudo adduser jenkins
sudo apt install docker.io -y
sudo usermod -aG docker $USER jenkins
newgrp docker

sudo apt-get update
sudo apt-get install wget -y
wget https://aquasecurity.github.io/trivy-repo/deb/public.key -O - | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy -y

docker run -d --name sonarqube -p 9000:9000 sonarqube:lts
docker run -d --name nexus -p 8081:8081 sonatype/nexus3
docker ps
```
<img width="1360" height="574" alt="image" src="https://github.com/user-attachments/assets/5a6e61c6-2dfe-4c0d-9acb-1ccbd054a3d3" />

### Access SonarQube Do Below setup:
- For SonarQube
  - user: admin
  - pass: admin
<img width="1365" height="517" alt="image" src="https://github.com/user-attachments/assets/0f699a21-d0a0-476e-9019-25ca3b348eda" />
- create a token and keep it same  ----  ex: squ_18ba3a47646daed7f61475c445d0c92e471ede4e
- Create a webhook ------ ex: http://13.235.215.21:8080/sonarqube-webhook/

- For Nexus:
  - user: admin
  - pass: do ---- docker exec -it 0a496397beb2 cat /nexus-data/admin.password
<img width="1365" height="485" alt="image" src="https://github.com/user-attachments/assets/d918f86d-b73d-4c6d-8538-bd48567fa218" />
- create three hosted repos in Nexus (one for snapshots and two for releases)
<img width="1025" height="236" alt="image" src="https://github.com/user-attachments/assets/241a7acd-5924-459b-9853-c97f6baa805b" />
- url's keep same will use in POM
```
http://13.204.89.141:8081/repository/Simple-webapp-snapshots/
http://13.204.89.141:8081/repository/Simple-webapp-releases/
http://13.204.89.141:8081/repository/Simple-webapp-rc-releases/
```

- add below lines of code to Pom.xml
```
<distributionManagement>
        <repository>
            <id>nexus-releases</id>
            <url>http://13.204.89.141:8081/repository/Simple-webapp-releases/</url>
        </repository>

        <snapshotRepository>
            <id>nexus-snapshots</id>
            <url>http://13.204.89.141:8081/repository/Simple-webapp-snapshots/</url>
        </snapshotRepository>
             
    </distributionManagement>
```



