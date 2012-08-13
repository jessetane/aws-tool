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
    util.picker "Please choose a blueprint", Blueprint.list(), "type", cb
    
  @pickRegionForBlueprint: (blueprint, cb) ->
    regions = Blueprint.listRegionsForBlueprint blueprint
    util.picker "Please choose a region", regions, null, cb
    
    
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
    rl = util.readline()
    rl.question "Name this instance? [name] ", (name) =>
      rl.close()
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
          id = data.instancesSet[0].instanceId
          console.log "Launching instance - " + id
          
          tags = {}
          if name?.length
            tags["ResourceId.1"] = id
            tags["Tag.1.Key"] = "Name"
            tags["Tag.1.Value"] = name
          tags["ResourceId.2"] = id
          tags["Tag.2.Key"] = "Type"
          tags["Tag.2.Value"] = @type
          
          ec2 "CreateTags", tags, (err, data) =>
            if err
              console.log "Failed to tag instance", err
            setTimeout =>
              console.log "Updating your info for " + @region
              aws.cache.updateAllForRegion @region
            , 500
    