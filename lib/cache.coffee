#
# Cache.coffee
#


_ = require "underscore"
fs = require "fs"
async = require "async"
aws = require.main.exports


module.exports = class Cache
  
  load: (cb) =>
    fs.readFile "#{aws.root}/.awscache", "utf8", (err, data) =>
      if not err
        try
          data = JSON.parse data
          @[key] = value for key, value of data
        catch parseErr
          err = parseErr
      cb err, data
  
  save: (cb) =>
    string = JSON.stringify @
    fs.writeFile ".awscache", string, cb
  
  updateAll: (cb) =>
    @regions = {}
    async.parallel [
      (cb) => @updateAddresses cb
      (cb) => @updateRegions cb
    ], (err) =>
      if not err
        ops = []
        _.each @regions, (region, regionName) =>
          ops.push (cb) => @updateAllForRegion regionName, cb
        async.parallel ops, cb
      else
        cb err

  updateAllForRegion: (region, cb) =>
    @regions[region] = {}
    async.parallel [
      (cb) => @updateAvailabilityZones region, cb
      (cb) => @updateInstances region, cb
    ], cb

  updateRegions: (cb) =>
    ec2 = aws.endpoint()
    ec2 "DescribeRegions", {}, (err, data) =>
      if not err
        data.regionInfo.forEach (region) =>
          @regions[region.regionName] ?= {}
          _.extend @regions[region.regionName], region
        console.log "Found #{_.size @regions} regions"
      cb err, @regions

  updateAvailabilityZones: (region, cb) =>
    ec2 = aws.endpoint region
    ec2 "DescribeAvailabilityZones", {}, (err, data) =>
      if not err
        @regions[region] ?= {}
        zones = @regions[region].availabilityZones ?= {}
        data.availabilityZoneInfo.forEach (zone) =>
          zones[zone.zoneName] ?= {}
          _.extend zones[zone.zoneName], zone
        console.log "Found #{_.size zones} availability zone(s) for", region
      cb err, @regions[region].availabilityZones

  updateInstances: (region, cb) =>
    ec2 = aws.endpoint region
    ec2 "DescribeInstances", {}, (err, data) =>
      if not err
        @regions[region] ?= {}
        count = 0
        _.each data.reservationSet, (reservation) =>
          _.each reservation.instancesSet, (instance) =>
            zone = instance.placement.availabilityZone
            zones = @regions[region].availabilityZones ?= {}
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

  updateAddresses: (cb) =>
    ec2 = aws.endpoint()
    ec2 "DescribeAddresses", {}, (err, data) =>
      if not err
        @addresses = data.addressesSet
        console.log "Found #{data.addressesSet.length} elastic IPs"
      cb err, data.addressesSet
