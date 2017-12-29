aws = require 'aws-sdk'

aws.config.accessKeyId = process.env.AWS_ACCESS_KEY_ID
aws.config.secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY
aws.config.region = process.env.AWS_REGION

module.exports =
  CloudFormation: new aws.CloudFormation()
  EC2: new aws.EC2()
