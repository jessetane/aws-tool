#
# Region.coffee
#

_ = require "underscore"
aws = require.main.exports
util = require "../../util/util"
proxy = util.proxy

module.exports = class AvilabilityZone
  
  @listZonesForRegion: (regionName) ->
    zones = []
    _.each aws.cache.regions[regionName]?.availabilityZones, (zone, name) ->
      zones.push new AvilabilityZone zone
      console.log " └─( " + zones.length + " )─ " + name
    return zones
  
  #
  #
  #
  
  @pickZoneForRegion: (region, cb) ->
    zones = AvilabilityZone.listZonesForRegion region
    util.picker "Please choose an availability zone", zones, "zoneName", cb  
  
  #
  #
  #
  
  util.proxy @, "zoneName", "data"
  
  constructor: (data) ->
    @data = data
