#
# Instance.coffee
#

_ = require "underscore"
aws = require.main.exports
util = require "../../util/util"
proxy = util.proxy

module.exports = class Instance
  
  #
  # Views
  #
  
  @list: ->
    instances = []
    console.log " • AWS Regions"
    _.each aws.cache.regions, (region, name) ->
      console.log " └─ " + name
      regionHasInstances = _.any region.availabilityZones, (zone) -> zone.instances?
      _.each region.availabilityZones, (zone, name) ->
        if regionHasInstances
          console.log "   └─ " + name
        _.each zone.instances, (instance) ->
          instance = new Instance instance
          instance.region = region.regionName  # HACK: some callers need region info though...
          instances.push instance
          msg = "     └─( " + instances.length + " )─ " + instance.id + " ─ "
          if instance.state isnt "running"
            msg += instance.state
          else
            msg += instance.dnsName
          if instance.tagSet?[0]?
            msg += " ─ " + instance.tagSet[0].key + ":" + instance.tagSet[0].value
          console.log msg
    return instances
  
  @actions: ->
    actions = []
    i = 1
    _.each Instance::, (method, action) ->
      if method
        console.log " └─( " + i++ + " )─ " + action + "()"
        actions.push action
    return actions
    

  #
  # Controls
  #
  
  @pickInstance: (cb) ->
    instances = Instance.list()
    pick = ->
      rl = util.readline()
      rl.question "Choose an instance [1-#{instances.length}] ", (i) ->
        rl.close()
        instance = util.selectNumericalChoice instances, i
        if instance
          console.log " • " + instance.id
          cb instance
        else
          console.log "Invalid choice"
          pick()
    pick()
  
  @pickAction: (cb) ->
    actions = Instance.actions()
    pick = ->
      rl = util.readline()
      rl.question "Choose an action [1-#{actions.length}] ", (i) ->
        rl.close()
        action = util.selectNumericalChoice actions, i
        if action 
          console.log " • " + action + "()"
          cb action
        else
          console.log "Invalid choice"
          pick()
    pick()

  
  #
  # Model
  #
  
  proxy @, "id", "data", "instanceId"
  proxy @, "region", "data"
  proxy @, "state", "data", "instanceState", "name"
  proxy @, "dnsName", "data"
  proxy @, "tagSet", "data"
  proxy @, "keyName", "data"
  
  constructor: (data) ->
    @data = data
  
  connect: =>
    rl = util.readline()
    rl.question "As what user? ", (user) =>
      rl.close()
      keypath = aws.config.keypairs[@keyName]
      command = "ssh -i " + keypath + " " + user + "@" + @dnsName
      exec = require("child_process").exec
      exec "uname -a | grep Darwin", (err, isMac) ->

        # if OSX we can use apple script
        # to open a new tab to open ssh
        if isMac
          exec "osascript -e 'tell application \"Terminal\" to activate' 
                          -e 'tell application \"System Events\" to tell process \"Terminal\" to keystroke \"t\" using command down'
                          -e 'tell application \"System Events\" to tell process \"Terminal\" to keystroke \"#{command}\"'
                          -e 'tell application \"System Events\" to keystroke return'"
        else
          console.log command
          ###
          #
          # instead we should just figure out how
          # to pipe node's terminal directly to ssh
          # it already sort of works:
          #
          exec = require('child_process').exec
          ssh = exec "ssh ec2-user@" + instance.dnsName + " -t -t -i " + keypath
          #
          ssh.stdout.on "data", (d) -> process.stdout.write d
          ssh.stderr.on "data", (d) -> process.stdout.write d
          ssh.on "exit", (d) ->
            process.stdin.pause()
            process.stdin.removeListener "data", pipe
          #
          pipe = (d) -> ssh.stdin.write d
          process.stdin.resume()
          process.stdin.on "keypress", pipe
          ###
    
  reboot: (cb) =>
    console.log "TODO"
    
  shutdown: (cb) =>
    console.log "TODO"
  
  terminate: (cb) =>
    rl = util.readline()
    rl.question "You are about to terminate " + @id + ". Are you sure? [yN] ", (yn) =>
      rl.close()
      if yn is "y" or yn is "Y"
        ec2 = aws.endpoint @region
        ec2 "TerminateInstances", { InstanceId: @id }, (err) ->
          if err
            console.log "Failed to terminate instance", err
          else
            console.log "Instance " + @id + " shutting down..."
            setTimeout -> 
              console.log "Updating your info for " + @region
              aws.cache.updateAllForRegion @region
            , 1000

