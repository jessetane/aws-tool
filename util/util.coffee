#
# util.coffee - misc functions
#

exports.selectNumericalChoice = (list, choice) ->
  choice = Number choice
  if choice is NaN or choice > list.length or choice < 1
    return null
  else
    list[Math.floor(choice)-1]    

exports.readline = ->
  readline = require "readline"
  readline.createInterface { input: process.stdin, output: process.stdout }

exports.proxy = (klass, name, container, originals...) ->
  klass::__defineGetter__ name, ->
    if originals.length is 0
      p = @[container]?[name]
    else
      p = @[container]
      originals.forEach (original) ->
        p = p?[original]
    return p
  klass::__defineSetter__ name, (val) -> 
    if originals.length is 0
      @[container][name] = val
    else
      c = @[container]
      originals.forEach (original, i) ->
        if i == originals.length-1
          if c?
            c[original] = val
        else
          c = c[original]
    return val
