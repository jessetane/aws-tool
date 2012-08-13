#
# manage.coffee
#


_ = require "underscore"
aws = require.main.exports

module.exports.instances = ->
  Instance = require "../Models/Instance"
  Instance.pickInstance (instance) ->
    Instance.pickAction (action) ->
      instance[action]()

module.exports.elasticIps = ->
  require("../models/ElasticIp").list()

module.exports.loadBalancers = ->
  require("../models/LoadBalancer").list()
