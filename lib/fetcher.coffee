#
# fetcher.coffee
#


async = require "async"
_ = require "underscore"


module.exports = class Fetcher
  
  constructor: (tool) ->
    @tool = tool
    @cache = tool.cache
    @cache.regions ?= {}
  
  all: (cb) =>
    @cache.regions = {}
    async.parallel [
      (cb) => @fetchAddresses cb
      (cb) => @fetchRegions cb
    ], (err) =>
      if not err
        ops = []
        _.each @cache.regions, (region, regionName) =>
          ops.push (cb) => @allForRegion regionName, cb
        async.parallel ops, cb
      else
        cb err
  
  allForRegion: (region, cb) =>
    @cache[region] = {}
    async.parallel [
      (cb) => @fetchAvailabilityZones region, cb
      (cb) => @fetchInstances region, cb
    ], cb
  
  fetchRegions: (cb) =>
    ec2 = @tool.endpoint()
    ec2 "DescribeRegions", {}, (err, data) =>
      if not err
        data.regionInfo.forEach (region) =>
          @cache.regions[region.regionName] ?= {}
          _.extend @cache.regions[region.regionName], region
        console.log "Found #{_.size @cache.regions} regions"
      cb err, @cache.regions
  
  fetchAvailabilityZones: (region, cb) =>
    ec2 = @tool.endpoint region
    ec2 "DescribeAvailabilityZones", {}, (err, data) =>
      if not err
        @cache.regions[region] ?= {}
        zones = @cache.regions[region].availabilityZones ?= {}
        data.availabilityZoneInfo.forEach (zone) =>
          zones[zone.zoneName] ?= {}
          _.extend zones[zone.zoneName], zone
        console.log "Found #{_.size zones} availability zone(s) for", region
      cb err, @cache.regions[region].availabilityZones
  
  fetchInstances: (region, cb) =>
    ec2 = @tool.endpoint region
    ec2 "DescribeInstances", {}, (err, data) =>
      if not err
        @cache.regions[region] ?= {}
        count = 0
        _.each data.reservationSet, (reservation) =>
          _.each reservation.instancesSet, (instance) =>
            zone = instance.placement.availabilityZone
            zones = @cache.regions[region].availabilityZones ?= {}
            zones[zone] ?= {}
            instances = zones[zone].instances ?= []
            replace = false
            _.each instances, (old, i) ->
              if old.instanceId == instance.instanceId
                instances[i] = instance
                replace = true
            if not replace
              zones[zone].instances.push instance
            count++
        console.log "Found #{count} instance(s) for", region
      cb err, zones?[zone].instances
  
  fetchAddresses: (cb) =>
    ec2 = @tool.endpoint()
    ec2 "DescribeAddresses", {}, (err, data) =>
      if not err
        @cache.addresses = data.addressesSet
        console.log "Found #{data.addressesSet.length} elastic IPs"
      cb err, data.addressesSet
