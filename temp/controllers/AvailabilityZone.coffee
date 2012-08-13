#
# Region.coffee
#

aws = require.main.exports
util = require "../../util/util"
proxy = util.proxy

module.exports = class AvilabilityZone
  
  @list: (regionName) ->
    zones = []
    _.each aws.cache.regions[regionName]?.availabilityZones, (zone, name) ->
      zones.push new AvilabilityZone zone
      console.log " └─( " + zones.length + " )─ " + name
    return zones
  
  @pick: ->
    console.log "TODO"
  
  #
  #
  #
  
  constructor: (data) ->
    @data = data
