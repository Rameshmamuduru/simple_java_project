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

## Launch EC2 and setup SonarQube,trivy,Nexus,Maven
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

sudo apt-get install maven -y

```

### Access SonarQube Do Below setup:

- For SonarQube
  - user: admin
  - pass: admin
<img width="1365" height="517" alt="image" src="https://github.com/user-attachments/assets/0f699a21-d0a0-476e-9019-25ca3b348eda" />

- create a token and keep it same

```
ex: squ_18ba3a47646daed7f61475c445d0c92e471ede4e
```
- Create a webhook

- For Nexus:
  - user: admin
  - pass: do ---- docker exec -it 0a496397beb2 cat /nexus-data/admin.password
  
<img width="1365" height="485" alt="image" src="https://github.com/user-attachments/assets/d918f86d-b73d-4c6d-8538-bd48567fa218" />


### Nexus Setup:

- create three hosted repos in Nexus (one for snapshots and two for releases)

<img width="1025" height="236" alt="image" src="https://github.com/user-attachments/assets/241a7acd-5924-459b-9853-c97f6baa805b" />

- url's keep same will use in POM
```
http://13.204.89.141:8081/repository/Simple-webapp-snapshots/
http://13.204.89.141:8081/repository/Simple-webapp-releases/
http://13.204.89.141:8081/repository/Simple-webapp-rc-releases/
http://13.204.89.141:8081/repository/Simple-webapp-maven-public/
http://13.204.89.141:8081/repository/Simple-webapp-maven-proxy/
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
- Do below for maven setting.xml
```
<servers>
    <server>
      <id>nexus-releases</id>
      <username>admin</username>
      <password>admin123</password>
    </server>

    <server>
      <id>nexus-snapshots</id>
      <username>admin</username>
      <password>admin123</password>
    </server>
  </servers>

<mirrors>
  <mirror>
    <id>nexus</id>
    <mirrorOf>*</mirrorOf>
    <url>http://<nexus-ip>:8081/repository/maven-public/</url>
  </mirror>
</mirrors>
```
**Note ID should with ID with POM**

- Run below command to validate the mvn+nexus
```
git clone <url?
mvn valiate
mvn dependency resolve
````
## setup password less authentication between master and slave:

- in Jenkins server (Master)

```
su - jenkins
ssh-keygen -t rsa
cd .ssh
cat id_rsa.pub
copy the public key
```

- In agent1
  
```
su - jenkins
mkdir ~/.ssh
mkdir ~/.ssh/authorized_keys
vim ~/.ssh/authorized_keys
Paste public key from jenkins master
chmod 700 ~/.ssh
chmod ~/.ssh/authorized_keys
login as root user
vim /etc/ssh/sshd_config

uncomment Below
PublicKeyAuthentication 
AutherizeKeyFile
PasswordAuthentication

systemctl restart ssh
```

- verify ssh from master
```
ssh jenkins@<agent_privateIP>
```
<img width="1364" height="602" alt="image" src="https://github.com/user-attachments/assets/a626c6fa-7771-4210-a95f-79ef3c28d9bd" />

## Jenkins configaration:

### Pluggins
- stage view
- sonarqube server
- Sonar Quality Gates
- Nexus Artifact Uploader

## Nodes (Agent Setup)
- Console-nodes-newnode
  - name: agent1
  - check permanent check box
  - Number of executors -2
  - remote root directory: /home/jenkins
  - Labels: agent1
  - Launch method Ssh: using private IP
  - add Host IP and add credential as sshusername and provate key
  - Host Key Verification Strategy: Manual trusted key verification
  - save
 
  <img width="1365" height="467" alt="image" src="https://github.com/user-attachments/assets/b31b5699-8f27-48d8-9696-8f0c984093e9" />


### System configaration in jenkins
- SonarQube Server:
  - server url: <http://13.204.89.141:9000>
  - Add global credential as secret text use sonarqube API token created earlier
  - SAVE
 
### Tools Configaration:
- SonarScanner
  - name: sonar-scanner
  - auto install
  - SAVE
  - 

