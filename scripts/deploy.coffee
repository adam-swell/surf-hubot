#
# Description:
#   Deploys the specified version of Surf
#
# Configuration:
#   AMI_NAME
#   AWS_ACCESS_KEY_ID
#   AWS_SECRET_ACCESS_KEY
#   AWS_REGION
#   HUBOT_SLACK_TOKEN
#   TEMPLATE_URL
#
# Commands:
#   @hubot deploy 1.0.0       - deploys that version of Surf (matches AMI <prefix>/1.0.0/*)
#   @hubot deploy 1.0.0/*789  - deploys that version + epoch of Surf (matches AMI <prefix>/1.0.0/56789)
#
# Author:
#   Adam <adam@swell-technologies.com>
#


ami = require '../lib/ami'
aws = require '../lib/aws'

module.exports = (robot) ->
  robot.respond /deploy\s?(.*)/i, (chat) ->
    ami.hasCorrespondingStack chat,
      """
      Need some help?

      You can deploy a _version_ of surf, if no instance of that _version_  is already deployed.
      The _version_ is governed by the image name, which I can provide if you ask for _status_.

      When you ask for _status_, you'll see something like:
      > ...
      >  #{process.env.AMI_NAME}/1.0.0/12345 built 2 hours ago
      > ...

      The _version_ is the bit after #{process.env.AMI_NAME}; don't worry, you don't have to type all that!
      The middle bit is the _number_ and the last bit is the _timestamp_.

      In this example, there is only one image with the _number_ 1.0.0, so I can deploy this image if you ask _deploy 1.0.0_.

      Now, suppose when you ask for status, you see something like:
      > ...
      >  #{process.env.AMI_NAME}/1.0.0/12345 built 2 hours ago
      >  #{process.env.AMI_NAME}/1.0.0/23456 built 2 hours ago
      > ...

      In this example, there are two images with the _number_ 1.0.0, so you must specify at least part of the _timestamp_.
      I can deploy the first image if you ask _deploy 1.0.0/*5_ or the last image if you ask _deploy 1.0.0/*6_.
      Also, you can type the whole _timestamp_ should you feel so inclined.
      """,
      # if the image already has a corresponding stack
      ((image) -> chat.send "Already deployed #{image.Name}!"),

      # if the image has no corresponding stack
      ((image) ->
        params =
          StackName: image.ImageId
          TemplateURL: process.env.TEMPLATE_URL
          Parameters: [{
            ParameterKey: "ImageId"
            ParameterValue: image.ImageId
            UsePreviousValue: false
          }]

        # create a new stack
        aws.CloudFormation.createStack params, (err) ->
          if err
            chat.send "Failed to deploy #{image.Name}!  Talk to Adam."
            console.error "deploy: #{err}"
          else
            chat.send "Deploying instance for #{image.Name} ...")
