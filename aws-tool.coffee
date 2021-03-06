#!/usr/bin/env coffee
#
# aws-tool.coffee
#

_ = require "underscore"
fs = require "fs"
ec2 = require "ec2"
path = require "path"


#
# Commands are dynamically routed
# just add one to the table below
# and pass it as an agument
#
commands =
  
  update: (region) ->
    cb = (err) ->
      if err
        console.log "Failed to get your info:\n\t", err
      else
        console.log "All your infos are belong to us" #\n", tool.cache
        aws.cache.save()
    if region
      aws.cache.updateAllForRegion region, cb
    else
      aws.cache.updateAll cb
  
  route: (what, args...) ->
    try
      router = require "./lib/routers/" + what
    catch err
      console.log "Unrecognized option"
      return false
    arg = args.shift()
    if router[arg]?
      router[arg] args...
    else
      console.log "Unrecognized option"
      return true
    return true

#
# The current working directory or a parent 
# must contain a ".aws" configuration file
#
loadConfig = (dir) ->
  fs.readFile dir + "/.aws", "utf8", (err, data) ->
    if err and dir is "/"
      console.log "You seem lost..."
    else if err
      loadConfig path.normalize dir + "/.."
    else
      try
        aws.root = dir
        aws.config = JSON.parse data
        aws.config.defaultRegion ?= "us-east-1"
        if aws.config.extensions
          loadExtensions()
        else
          loadCache()
      catch err
        console.log "Failed to parse #{dir}/.aws\n\t", err

#
# Config extensions
#
loadExtensions = ->
  aws.config.extensions.forEach (extensionFile) ->
    extensionFile = aws.root + "/" + extensionFile
    try
      data = fs.readFileSync extensionFile, "utf8"
      extension = JSON.parse data
      for section, data of extension
        if _.isObject data
          aws.config[section] ?= {}
          aws.config[section] = _.extend aws.config[section], data
        else
          aws.config[section] = data
    catch err
      console.log "Failed to load extension \"#{extensionFile}\":", err
  loadCache()


#
# Since the API isn't super fast, we cache
# any data we pull down in a ".awscache" file
#
loadCache = ->
  Cache = require "./lib/cache"
  aws.cache = new Cache
  aws.cache.load (err) ->
    if err
      console.log "First time? Getting your info from Amazon..."
      aws.cache.updateAll (err) ->
        if err
          console.log "Failed to get your info:\n\t", err
        else
          aws.cache.save()
    else
      handleArgs()


#
# Handles the dynamic command routing -
# add new commands directly to the commands 
# table at the top and pass them as 1st arg
#
handleArgs = ->
  args = process.argv.slice 2
  arg = args.shift()
  if commands[arg]? then commands[arg] args...
  else if commands.route (process.argv.slice 2)...
  else
    console.log "I'm sorry Dave..."


#
# The module exports references
# to the cache, config, and an api endpoint generator
#
module.exports = aws =
  cache: null
  config: null
  commands: commands
  endpoint: (region) ->
    ec2
      key: @config.key
      secret: @config.secret
      endpoint: region or aws.config.defaultRegion


# Kicks things off by searching 
# for an ".aws" file in the cwd
loadConfig process.cwd()
