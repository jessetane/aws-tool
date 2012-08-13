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
  
  #
  #
  #
  
  constructor: (data) ->
    @data = data