#
# Instance.coffee
#

_ = require "underscore"
aws = require.main.exports
util = require "../../util/util"
shell = require "shell"
proxy = util.proxy

module.exports = class Instance
  
  @list: ->
    instances = []
    console.log " • AWS Regions"
    _.each aws.cache.regions, (region, regionName) ->
      console.log " └─ " + regionName
      regionHasInstances = _.any region.availabilityZones, (zone) -> zone.instances?
      _.each region.availabilityZones, (zone, zoneName) ->
        if regionHasInstances
          console.log "   └─ " + zoneName
        _.each zone.instances, (instance) ->
          instance = new Instance instance
          instance.region = regionName  # HACK: some callers need region info though...
          instances.push instance
          msg = "     └─( " + instances.length + " )─ " + instance.id + " ─ "
          if instance.state isnt "running"
            msg += instance.state
          else
            msg += instance.dnsName
          if instance.tagSet?.length
            msg += " ─ "
            msg += instance.tags.join " ─ "
          console.log msg
    return instances
  
  @actions: ->
    actions = []
    _.each [ "command", "connect", "terminate" ], (action) ->
      actions.push action
      console.log " └─( " + actions.length + " )─ " + action + "()"
    return actions
  
  @commands: ->
    commands = []
    _.each aws.config.commands, (cmd, name) ->
      commands.push name
      console.log " └─( " + commands.length + " )─ " + name + "()"
    return commands
  
  #
  #
  #
  
  @pickInstance: (cb) ->
    util.picker "Choose a instance", Instance.list(), [ "id", "tagString" ], cb  # note - add tag!
  
  @pickAction: (cb) ->
    util.picker "Choose a action", Instance.actions(), null, cb

  @pickCommand: (cb) ->
    util.picker "Choose a command", Instance.commands(), null, cb
    
  
  #
  #
  #
  
  proxy @, "id", "data", "instanceId"
  proxy @, "state", "data", "instanceState", "name"
  proxy @, "dnsName", "data"
  proxy @, "tagSet", "data"
  proxy @, "keyName", "data"
  @::__defineGetter__ "tags", ->
    tagSet = _.sortBy @tagSet, (tag) -> tag.key
    tagSet.map (tag) -> tag.key + ":" + tag.value
  @::__defineGetter__ "tagString", ->
    @tags.join " ─ "
  
  
  constructor: (data) ->
    @data = data
  
  command: =>
    Instance.pickCommand (cmd) =>
      cmd = aws.config.commands[cmd]
      user = cmd.user
      keypair = aws.config.keypairs[cmd.keypair]
      
      generateCommand = (script) =>
        shell aws.root + "/" + script, (err, command) =>
          if not err
            #command = command.replace /'/g, "\\'"
            runCommand command
          else
            console.log "Failed to load command from script \"#{cmd.command.script}\":", err

      runCommand = (command) =>
        command = "ssh -tt -i #{aws.root + "/" + keypair} #{user}@#{@dnsName} '#{command}'"
        cmd = shell command
        cmd.stdout.on "data", (d) -> process.stdout.write d
        cmd.stderr.on "data", (d) -> process.stdout.write d
      
      if typeof cmd.command is "string"
        runCommand cmd.command
      else
        script = cmd.command.script
        params = cmd.command.params
        getParam = ->
          if not params or params.length == 0
            generateCommand script
          else
            rl = util.readline()
            rl.question params.shift(), (answer) =>
              script += " "
              script += answer
              rl.close()
              getParam()
        getParam()
        
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
          ssh.stdout.on "data", (d) -> process.stdout.write d
          ssh.stderr.on "data", (d) -> process.stdout.write d
          ssh.on "exit", (d) ->
            process.stdin.pause()
            process.stdin.removeListener "data", pipe
          pipe = (d) -> ssh.stdin.write d
          process.stdin.resume()
          process.stdin.on "keypress", pipe
          ###
        
  terminate: (cb) =>
    rl = util.readline()
    rl.question "You are about to terminate " + @id + ". Are you sure? [yN] ", (yn) =>
      rl.close()
      if yn is "y" or yn is "Y"
        ec2 = aws.endpoint @region
        ec2 "TerminateInstances", { InstanceId: @id }, (err) =>
          if err
            console.log "Failed to terminate instance", err
          else
            console.log "Instance " + @id + " shutting down..."
            setTimeout => 
              console.log "Updating your info for " + @region
              aws.cache.updateAllForRegion @region
            , 1000
