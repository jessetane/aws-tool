#
# add.coffee
#


_ = require "underscore"
aws = require.main.exports

module.exports.instances = ->
  Blueprint = require "../Models/Blueprint"
  AvailabilityZone = require "../Models/AvailabilityZone"
  Blueprint.pickBlueprint (blueprint) ->
    Blueprint.pickRegionForBlueprint blueprint, (region) ->
      AvailabilityZone.pickZoneForRegion region, (zone) ->
        blueprint.region = region
        blueprint.availabilityZone = zone
        blueprint.deploy()

module.exports.elasticIps = ->
  require("../models/ElasticIp").list()

module.exports.loadBalancers = ->
  require("../models/LoadBalancer").list()
