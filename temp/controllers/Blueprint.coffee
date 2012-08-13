#
# Blueprint.coffee
#

aws = require.main.exports
util = require "../../util/util"
proxy = util.proxy

module.exports = class Blueprint
  
  @list: ->
    blueprints = []
    _.each aws.config.blueprints, (blueprint, name) ->
      blueprints.push name
      console.log " └─( " + blueprints.length + " )─ " + name
    return blueprints
  
  @pick: ->
    blueprints = Blueprint.list()
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
  #
  #
  
  constructor: (data) ->
    @data = data
  
  listRegions: ->
    regions = []
    _.each @regions, (ami, region) ->
      regions.push region
      console.log " └─( " + regions.length + " )─ " + region
    return regions
  
  launch: ->
    
    