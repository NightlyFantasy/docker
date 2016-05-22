### Docker

#### Software

* CentOS 7 latest
* PHP 7 latest
* Nginx stable latest

### Install Docker

CentOS : `sudo yum install docker -y`
Ubuntu/Debian: `sudo apt-get install docker.io`

### Usage

* Clone this repo: `git clone https://github.com/Leepin/docker`
* Cd in: `cd docker`
* Build it: `docker build -t webserver .`
* Run it: `docker run -d -p 80:80 webserver`