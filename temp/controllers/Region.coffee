#
# Region.coffee
#

aws = require.main.exports
util = require "../../util/util"
proxy = util.proxy

module.exports = class Region
  
  @list: ->
    regions = []
    _.each aws.cache.regions, (region, name) ->
      regions.push region
      console.log " └─( " + regions.length + " )─ " + name
    return regions
  
  @pick: ->
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
  #
  #
  
  constructor: (data) ->
    @data = data