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
    console.log " • - " + regionName
    _.each aws.cache.regions[regionName]?.availabilityZones, (zone, name) ->
      zones.push new AvilabilityZone zone
      console.log " └─( " + zones.length + " )─ " + name
    return zones
  
  #
  #
  #
  
  @pickZoneForRegion: (region, cb) ->
    zones = AvilabilityZone.listZonesForRegion region
    pick = ->
      rl = util.readline()
      rl.question "Please choose an availability zone [1-#{zones.length}] ", (i) ->
        rl.close()
        zone = util.selectNumericalChoice zones, i
        if zone then cb zone
        else
          console.log "Invalid choice"
          pick()
    pick()
  
  
  #
  #
  #
  
  util.proxy @, "zoneName", "data"
  
  constructor: (data) ->
    @data = data
