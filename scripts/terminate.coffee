#
# Description:
#   Terminates the specified version of Surf
#
# Configuration:
#   AWS_ACCESS_KEY_ID
#   AWS_SECRET_ACCESS_KEY
#   AWS_REGION
#   HUBOT_SLACK_TOKEN
#
# Commands:
#   @hubot deploy 1.0.0       - terminates that version of Surf (matches AMI <prefix>/1.0.0/*)
#   @hubot deploy 1.0.0/*789  - terminates that version + epoch of Surf (matches AMI <prefix>/1.0.0/56789)
#
# Author:
#   Adam <adam@swell-technologies.com>
#

ami = require '../lib/ami'
aws = require '../lib/aws'


module.exports = (robot) ->
  robot.respond /terminate\s?(.*)/i, (chat) ->
    ami.hasCorrespondingStack chat,
      """
      Need some help?

      You can terminate a _version_ of surf, if an instance of that _version_ is already deployed.
      The _version_ is governed by the image name, which I can provide if you ask for _status_.

      When you ask for _status_, you'll see something like:
      > ...
      >  #{process.env.AMI_NAME}/1.0.0/12345 built 2 hours ago
      > ...

      The _version_ is the bit after #{process.env.AMI_NAME}; don't worry, you don't have to type all that!
      The middle bit is the _number_ and the last bit is the _timestamp_.

      In this example, there is only one image with the _number_ 1.0.0, so I can terminate this image if you ask _terminate 1.0.0_.

      Now, suppose when you ask for status, you see something like:
      > ...
      >  #{process.env.AMI_NAME}/1.0.0/12345 built 2 hours ago
      >  #{process.env.AMI_NAME}/1.0.0/23456 built 2 hours ago
      > ...

      In this example, there are two images with the _number_ 1.0.0, so you must specify at least part of the _timestamp_.
      I can terminate the first image if you ask terminate 1.0.0/*5_ or the last image if you ask _terminate 1.0.0/*6_.
      Also, you can type the whole _timestamp_ should you feel so inclined.
      """,
      ((image) ->
        aws.CloudFormation.deleteStack { StackName: image.ImageId }, (err) ->
          if err
            chat.send "AWS failed to deploy #{name}!  Talk to Adam."
            console.error "terminate: #{err}"
          else
            chat.send "Terminating instance for #{image.Name} ..."),
      ((image) ->
        chat.send "#{image.Name} not deployed!")

