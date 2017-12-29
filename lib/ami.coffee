aws = require('./aws')


captureInput = (chat, help, callback) ->
  input = chat.match[1]

  if input is ''
    chat.send help
  else
    version = captureVersion(input)
    time = captureTime(input)

    if version is null
      chat.send """
                Cannot process '#{input}'; no matching version found!  Please try again.

                #{help}
                """
    else
      name = if time isnt null then "#{version}/#{time}" else "#{version}/*"
      name = "surf-instance/#{name}"

      callback.call this, name

captureTime = (input) ->
  capture = /\/(\*\d+)$/.exec(input)
  if capture then capture[1] else null

captureVersion = (input) ->
  capture = /^(\d+\.\d+\.\d+)/.exec(input)
  if capture then capture[1] else null

hasDeployedStack = (chat, image, whenHasStack,whenHasNoStack) ->
  aws.CloudFormation.describeStacks { StackName: image.ImageId }, (err, data) ->
    if err
      whenHasNoStack.call this, image
    else
      state = data.Stacks[0].StackStatus

      switch data.Stacks[0].StackStatus
        when 'CREATE_COMPLETE'
          whenHasStack.call this, image
        when 'DELETE_COMPLETE'
          whenHasNoStack.call this, image
        when 'CREATE_IN_PROGRESS', 'DELETE_IN_PROGRESS'
          inTransition = if state is 'CREATE_IN_PROGRESS' then 'deploying' else 'terminating'
          chat.send "#{image.Name} is #{inTransition} ..."
        when 'CREATE_FAILED', 'DELETE_FAILED', 'ROLLBACK_COMPLETE', 'ROLLBACK_FAILED', 'ROLLBACK_IN_PROGRESS'
          chat.send "#{image.Name} failed in its last action; tell Adam."
          chat.send "(mention the stack state for #{image.Name} is #{state})"
        else
          chat.send "Not sure how #{image.Name} got in its current state; tell Adam."
          chat.send "(mention the stack state for #{image.Name} is #{state})"

findOne = (chat, name, callback) ->
  params =
    Filters: [{
      Name: 'name', Values: [ name ]
    }]

  aws.EC2.describeImages params, (err, data) ->
    if err
      chat.send "AWS failed to describe #{name}!  Tell Adam."
      console.error "ami#describeImages: #{err}"
    else if data.Images.length is 0
      chat.send "Nothing matched #{name}!"
    else if data.Images.length > 1
      chat.send "Many things matched #{name}; try being more specific."
    else
      callback.call this, data.Images[0]


module.exports =
  hasCorrespondingStack: (chat, help, whenHasStack, whenNoHasStack) ->
    captureInput chat, help, (name) ->
      findOne chat, name, (image) ->
        hasDeployedStack chat, image, whenHasStack, whenNoHasStack