#
# Description:
#   Sends help!
#
# Configuration:
#   HUBOT_SLACK_TOKEN
#
# Commands:
#   @hubot help - sends help!
#
#
# Author:
#   Adam <adam@swell-technologies.com>
#

module.exports = (robot) ->
  robot.respond /help/i, (chat) ->
    chat.send """
              Hi there!  Need some help?

              I can do a few things:
              * give _status_ of surf images and instances
              * _deploy_ a surf instance
              * _terminate_ a surf instance

              Just mention any of the _keywords_ above for more information.
              """