#
# terminate - ssh into a box
#


util = require "../util/util"
display = require "./display"

tool = null
cache = null
instance = null

module.exports = (t) ->
  tool = t
  pickInstance()
  
pickInstance = ->
  instances = display.showInstances tool
  pick = ->
    rl = util.readline()
    rl.question "Please choose an instance [1-#{instances.length}] ", (i) ->
      rl.close()
      instance = util.selectNumericalChoice instances, i
      if instance then terminate()
      else
        console.log "Invalid choice"
        pick()
  pick()


#
# Take down
#
terminate = ->
  id = instance.instanceId
  rl = util.readline()
  rl.question "You are about to terminate " + id + ". Are you sure? [yN] ", (yn) ->
    rl.close()
    if yn is "y" or yn is "Y"
      ec2 = tool.endpoint instance.region
      ec2 "TerminateInstances", { InstanceId: id }, (err) ->
        if err
          console.log "Failed to terminate instance", err
        else
          console.log "Instance " + id + " shutting down..."
          setTimeout -> 
            console.log "Updating your info for " + instance.region
            tool.commands.update instance.region
          , 1000
  