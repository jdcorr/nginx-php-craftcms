# Craft CMS Docker Boilerplate

## Craft CMS

This project utilizes Craft CMS to manage custom data entries. Find out more at: (https://craftcms.com/ and http://craftcms.stackexchange.com/)

## Docker Implementation

### PreReqs

1. Install Docker Engine https://docs.docker.com/engine/installation/
2. Install Docker Compose https://docs.docker.com/compose/install/
3. Install Virtualbox https://www.virtualbox.org/wiki/Downloads

### Setup Docker locally

1. Create a new Docker env `docker-machine create [NAME OF ENV] --driver virtualbox`
2. `docker-machine env [NAME OF ENV]`
3. `eval $(docker-machine env [NAME OF ENV])`
4. `docker-compose up -d`

### Setup Docker Environment to point to AWS instance

To initially create the image, follow the instructions here: https://docs.docker.com/machine/examples/aws/

1. Create AWS machine
`docker-machine create --driver amazonec2 --amazonec2-region us-west-1 slice-technologies-dev`

Otherwise, if environment already exists:

1. Switch your docker-env to point to Dev Instance on AWS
`docker-machine env [NAME OF ENV]`

2. After that completes, run the command it prompts you with:
`eval $(docker-machine env [NAME OF ENV])`

3. Run the following command to rebuild the containers (if required), and restart them. The `-d` flag tells the process to run as a daemon:
`docker-compose up -d`

4. If all goes well you will see a message similar to:

```
Recreating mariadb_1
redis_1 is up-to-date
Recreating web_1
```

5. View your changes at the corresponding url where you've deployed

### Setup AWS Elastic Beanstalk
1. Visit Elastic Beanstalk section in AWS Admin Panel
2. Create a new application named Slice
3. Create a new environment named slice-staging with the application type of Docker Multi-container

### Deploy to AWS Elastic Beanstalk
1. Zip up all files within the repo and use that zip as the source to upload into Elastic Beanstalk by clicking the Upload and Deploy button. Additionally, you can use the EB cli to do this from the command line (http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3.html) to bypass the AWS UI, if preferred.

*Important* Be sure only the most recent backup file is under `/craft/storage/backups`, if there are multiple versions, the data import feature can fail.

2. App will build/rebuild and can be viewed via the url of the elasticbeanstalk instance.
