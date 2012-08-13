#
# provision
#


fs = require "fs"
util = require "../util/util"
display = require "./display"


tool = null
cache = null
blueprint = null
region = null
ami = null
zone = null

module.exports = (t) ->
  tool = t
  pickBlueprint()


#
# Blueprints are designated in the .aws file
#
pickBlueprint = ->
  blueprints = display.showBlueprints tool
  pick = ->
    rl = util.readline()
    rl.question "Please choose a blueprint [1-#{blueprints.length}] ", (i) ->
      rl.close()
      blueprint = util.selectNumericalChoice blueprints, i
      if blueprint then pickRegion()
      else
        console.log "Invalid choice"
        pick()
  pick()


#
# You'll need to manually designate an AMI 
# for each region you'd like to deploy in
#
pickRegion = ->
  regions = display.showBlueprintRegions tool, blueprint
  pick = ->
    rl = util.readline()
    rl.question "Please choose a region [1-#{regions.length}] ", (i) ->
      rl.close()
      region = util.selectNumericalChoice regions, i
      if region then pickZone()
      else
        console.log "Invalid choice"
        pick()
  pick()


#
# Availability zone?
#
pickZone = ->
  zones = display.showAvailabilityZonesForRegion tool, region
  pick = ->
    rl = util.readline()
    rl.question "Please choose an availability zone [1-#{zones.length}] ", (i) ->
      rl.close()
      zone = util.selectNumericalChoice zones, i
      if zone then deploy()
      else
        console.log "Invalid choice"
        pick()
  pick()


#
# Run instances
#
deploy = ->
  data = tool.config.blueprints[blueprint]
  userdata = fs.readFileSync tool.root + "/" + data.user_data, "Base64"
  instance = 
    "Placement.AvailabilityZone": zone.zoneName
    UserData: userdata
    ImageId: data.regions[region] 
    KeyName: data.keyname
    InstanceType: data.size
    MinCount: 1
    MaxCount: 1
  
  ec2 = tool.endpoint region
  ec2 "RunInstances", instance, (err, data) ->
    if err
      console.log "Failed to launch instance", err
    else
      console.log "Launching instance - " + data.instancesSet[0].instanceId
      setTimeout ->
        console.log "Updating your info for " + region
        tool.commands.update region
      , 500
