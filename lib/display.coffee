#
# display.coffee
#


_ = require "underscore"


module.exports.showRegions = (tool) ->
  regions = []
  _.each tool.cache.regions, (region, name) ->
    regions.push region
    console.log " └─( " + regions.length + " )─ " + name
  return regions
  
module.exports.showAvailabilityZonesForRegion = (tool, regionName) ->
  zones = []
  _.each tool.cache.regions[regionName]?.availabilityZones, (zone, name) ->
    zones.push zone
    console.log " └─( " + zones.length + " )─ " + name
  return zones

module.exports.showInstances = (tool) ->
  regions = tool.cache.regions
  instances = []
  _.each regions, (region, name) ->
    console.log " └─ " + name
    _.each region.availabilityZones, (zone, name) ->
      if zone.instances
        console.log "   └─ " + name
      _.each zone.instances, (instance) ->
        instance.region = region.regionName  # HACK: some callers need region info though...
        instances.push instance
        msg = "     └─( " + instances.length + " )─ " + instance.instanceId + " ─ "
        if instance.instanceState.name isnt "running"
          msg += instance.instanceState.name
        else
          msg += instance.dnsName
        if instance.tagSet?[0]?
          msg += " ─ " + instance.tagSet[0].key + ":" + instance.tagSet[0].value
        console.log msg
  return instances
  
module.exports.showElasticIps = (tool) ->
  elasticIPs = []
  _.each tool.cache.addresses, (ip) ->
    elasticIPs.push ip
    console.log " └─( " + elasticIPs.length + " )─ " + ip.publicIp
  return elasticIPs
  
module.exports.showBlueprints = (tool) ->
  blueprints = []
  _.each tool.config.blueprints, (blueprint, name) ->
    blueprints.push name
    console.log " └─( " + blueprints.length + " )─ " + name
  return blueprints

module.exports.showBlueprintRegions = (tool, blueprint) ->
  regions = []
  if typeof blueprint is "string"
    blueprint = tool.config?.blueprints[blueprint]
  _.each blueprint?.regions, (ami, region) ->
    regions.push region
    console.log " └─( " + regions.length + " )─ " + region
  return regions
