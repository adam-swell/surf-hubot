#
# Description:
#   Lists all available versions of Surf.
#
# Dependencies:
#   "moment": ""
#
# Configuration:
#   AMI_NAME
#   AWS_ACCESS_KEY_ID
#   AWS_ACCOUNT_NUMBER
#   AWS_SECRET_ACCESS_KEY
#   AWS_REGION
#   HUBOT_SLACK_TOKEN
#
# Commands:
#   @hubot status - lists images built and instances pending or running
#
#
# Author:
#   Adam <adam@swell-technologies.com>
#

aws = require '../lib/aws'
moment = require 'moment'


describeImages = (chat, callback) ->
  params =
    Filters: [{
      Name: 'name', Values: [ "#{process.env.AMI_NAME}/*" ]
    }]
    Owners: [ process.env.AWS_ACCOUNT_NUMBER ]


  aws.EC2.describeImages params, (err, data) ->
    if err
      chat.send 'AWS failed to list the images!  Talk to Adam.'
      console.error "list#describeImages: #{err}"
    else if data.Images.length == 0
      chat.send "No images built!"
    else
      callback.call null, data.Images


describeInstances = (chat, images, callback) ->
  params =
    Filters: [{
      Name: 'image-id',
      Values: images.map (image) -> image.ImageId
    }, {
      Name: 'instance-state-name'
      Values: [ 'pending', 'running' ]
    }]

  aws.EC2.describeInstances params, (err, data) ->
    if err
      chat.send 'AWS failed to list the instances!  Talk to Adam.'
      console.error "list#describeInstances: #{err}"
    else if data.Reservations.length == 0
      chat.send 'No instances launched!'
    else
      for reservation in data.Reservations
        determineInstanceStatus chat, reservation.Instances, callback

determineInstanceStatus = (chat, instances, callback) ->
  params =
    InstanceIds: instances.map (instance) -> instance.InstanceId

  aws.EC2.describeInstanceStatus params, (err, data) ->
    if err
      chat.send "AWS failed to list instance statuses!  Talk to Adam."
      console.error "status: #{err}"
    else
      statuses = {}

      for status in data.InstanceStatuses
        instance = status.InstanceStatus.Status
        system = status.SystemStatus.Status
        statuses[status.InstanceId] = instance is 'ok' and system is 'ok'

      instances = instances.map (instance) -> {
        ImageId: instance.ImageId
        LaunchTime: instance.LaunchTime
        PublicIpAddress: instance.PublicIpAddress
        State: { Name: instance.State.Name }
        Status: statuses[instance.InstanceId]
      }

      callback.call null, instances

determineState = (instance) ->
  switch instance.State.Name
    when "running"
      if instance.Status
        "running at http://#{instance.PublicIpAddress}"
      else
        "running but not ready ..."
    else
      instance.State.Name

module.exports = (robot) ->
  robot.respond /status/i, (chat) ->
    chat.send "Sure thing, boss!"

    describeImages chat, (images) ->
      names = {}

      for image in images
        names[image.ImageId] = image.Name
        atMoment = moment(image.CreationDate, moment.ISO_8601).fromNow()
        chat.send "#{image.Name} built #{atMoment}"

      describeInstances chat, images, (instances) ->
        for instance in instances
          name = names[instance.ImageId]
          atMoment = moment(instance.LaunchTime, moment.ISO_8601).fromNow()
          inState = determineState instance

          chat.send "#{name} launched #{atMoment} and is #{inState}"

