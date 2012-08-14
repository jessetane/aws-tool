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
      @name = name
      
      # user data is either a string, an array of file paths, or a script that generates a string
      if _.isString @user_data
        @runInstances()
      else if _.isArray @user_data
        data = ""
        for script in @user_data
          try
            data += fs.readFileSync aws.root + "/" + script
          catch err
            console.log "Failed to load user_data file:", script
            return
        @user_data = data
        @runInstances()
      else
        shell @user_data.script, (err, data) =>
          if not err
            @user_data = data
            @runInstances()
          else
            console.log "user_data generator failed:", err
            
  runInstances: =>
    params = 
      "Placement.AvailabilityZone": @availabilityZone.zoneName
      UserData: new Buffer(@user_data).toString "base64"
      ImageId: @regions[@region]
      KeyName: @keyname
      InstanceType: @size
      MinCount: 1
      MaxCount: 1
    @ec2 = aws.endpoint @region
    @ec2 "RunInstances", params, (err, data) =>
      if err
        console.log "Failed to launch instance", err
      else
        @id = data.instancesSet[0].instanceId
        console.log "Launching instance - " + @id
        @createTags()
    
  createTags: =>
    params = {}
    if @name?.length
      params["ResourceId.1"] = @id
      params["Tag.1.Key"] = "Name"
      params["Tag.1.Value"] = @name
    params["ResourceId.2"] = @id
    params["Tag.2.Key"] = "Type"
    params["Tag.2.Value"] = @type
    @ec2 "CreateTags", params, (err, data) =>
      if err
        console.log "Failed to tag instance", err
      setTimeout =>
        console.log "Updating your info for " + @region
        aws.cache.updateAllForRegion @region
      , 500
