#
# ElasticIp.coffee
#

aws = require.main.exports
util = require "../../util/util"
proxy = util.proxy

module.exports = class ElasticIp
  
  @list: ->
    elasticIPs = []
    _.each aws.cache.addresses, (ip) ->
      elasticIPs.push new ElasticIp ip
      console.log " └─( " + elasticIPs.length + " )─ " + ip.address
    return elasticIPs
  
  @pick: ->
    console.log "TODO"
  
  #
  #
  #
  
  @proxy "address", "data", "publicIp"
  
  constructor: (data) ->
    @data = data

  add: (cb) ->
    console.log "TODO"
  
  remove: (cb) ->
    console.log "TODO"
    
  associate: (instance, cb) ->
    console.log "TODO"
