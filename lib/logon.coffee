#
# logon - ssh into a box
#


util = require "../util/util"
display = require "./display"

tool = null
user = null
cache = null
instance = null

module.exports = (t, u) ->
  tool = t
  user = u
  if not u
    console.log "Please specify the remote user"
    return
  pickInstance()
  
pickInstance = ->
  instances = display.showInstances tool
  pick = ->
    rl = util.readline()
    rl.question "Please choose an instance [1-#{instances.length}] ", (i) ->
      rl.close()
      instance = util.selectNumericalChoice instances, i
      if instance then connectTo instance
      else
        console.log "Invalid choice"
        pick()
  pick()


#
# for now, just print out the command
# it should be possible to pipe ssh in/out of node
#
connectTo = (instance) ->
  keypath = tool.config.keypairs[instance.keyName]
  command = "ssh -i " + keypath + " " + user + "@" + instance.dnsName
  exec = require("child_process").exec
  exec "uname -a | grep Darwin", (err, isMac) ->
    
    # if OSX we can use apple script
    # to open a new tab to open ssh
    if isMac
      exec "osascript -e 'tell application \"Terminal\" to activate' 
                      -e 'tell application \"System Events\" to tell process \"Terminal\" to keystroke \"t\" using command down'
                      -e 'tell application \"System Events\" to tell process \"Terminal\" to keystroke \"#{command}\"'
                      -e 'tell application \"System Events\" to keystroke return'"
    
    # instead we should just figure out how
    # to pipe node's terminal directly to ssh
    else
      console.log command
      ###

      #
      # pipe SSH directly to/from node, sort of works...
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
