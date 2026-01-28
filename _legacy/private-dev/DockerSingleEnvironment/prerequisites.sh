# 1. Install cURL
sudo apt-get update
sudo apt-get install curl

echo "successfully Installed Curl"

#2. Install Docker
sudo apt-get update

sudo apt-get install \
apt-transport-https \
ca-certificates \
curl \
gnupg-agent \
software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) \
test"

sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io

echo "successfully Installed Docker"

#3. Install Docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

#4. Go programming language
 # No installation required as we write chaincode in Node JS.

#5.Install npm and node js
sudo apt-get update
sudo apt-get install nodejs
sudo apt install npm
sudo npm install npm@5.6.0 -g
sudo usermod -aG docker $USER
