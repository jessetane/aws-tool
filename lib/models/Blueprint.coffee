#
# Blueprint.coffee
#

_ = require "underscore"
fs = require "fs"
aws = require.main.exports
util = require "../../util/util"
proxy = util.proxy

module.exports = class Blueprint
  
  @list: ->
    blueprints = []
    _.each aws.config.blueprints, (blueprint, name) ->
      blueprint = new Blueprint blueprint
      blueprint.type = name
      blueprints.push blueprint
      console.log " └─( " + blueprints.length + " )─ " + name
    return blueprints
  
  @listRegionsForBlueprint: (blueprint) ->
    regions = []
    _.each blueprint.regions, (ami, region) ->
      regions.push region
      console.log " └─( " + regions.length + " )─ " + region
    return regions
  
  #
  #
  #
  
  @pickBlueprint: (cb) ->
    blueprints = Blueprint.list()
    pick = ->
      rl = util.readline()
      rl.question "Please choose a blueprint [1-#{blueprints.length}] ", (i) ->
        rl.close()
        blueprint = util.selectNumericalChoice blueprints, i
        if blueprint then cb blueprint
        else
          console.log "Invalid choice"
          pick()
    pick()
    
  @pickRegionForBlueprint: (blueprint, cb) ->
    regions = Blueprint.listRegionsForBlueprint blueprint
    pick = ->
      rl = util.readline()
      rl.question "Please choose a region [1-#{regions.length}] ", (i) ->
        rl.close()
        region = util.selectNumericalChoice regions, i
        if region then cb region
        else
          console.log "Invalid choice"
          pick()
    pick()
    
  #
  #
  #
  
  util.proxy @, "size", "data"
  util.proxy @, "region", "data"
  util.proxy @, "regions", "data"
  util.proxy @, "keyname", "data"
  util.proxy @, "user_data", "data"
  
  
  constructor: (data) ->
    @data = data
  
  deploy: =>
    userdata = fs.readFileSync aws.root + "/" + @user_data, "Base64"
    instance = 
      "Placement.AvailabilityZone": @availabilityZone.zoneName
      UserData: userdata
      ImageId: @regions[@region] 
      KeyName: @keyname
      InstanceType: @size
      MinCount: 1
      MaxCount: 1
      
    ec2 = aws.endpoint @region
    ec2 "RunInstances", instance, (err, data) =>
      if err
        console.log "Failed to launch instance", err
      else
        console.log "Launching instance - " + data.instancesSet[0].instanceId
        setTimeout =>
          console.log "Updating your info for " + @region
          aws.cache.updateAllForRegion @region
        , 500
    