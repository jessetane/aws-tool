#
# show.coffee
#


_ = require "underscore"
aws = require.main.exports


module.exports.regions = ->
  require("../models/Region").list()
  
module.exports.availabilityZonesForRegion = (regionName) ->
  require("../models/AvailabilityZone").list regionName

module.exports.instances = ->
  require("../models/Instance").list()
  
module.exports.elasticIps = ->
  require("../models/ElasticIp").list()
  
module.exports.blueprints = ->
  require("../models/Blueprint").list()

module.exports.regionsForBlueprint = (blueprint) ->
  if typeof blueprint is "string"
    blueprint = aws.config.blueprints[blueprint]
