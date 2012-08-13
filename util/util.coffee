#
# util.coffee - misc functions
#

module.exports.selectNumericalChoice = (list, choice) ->
  choice = Number choice
  if choice is NaN or choice > list.length or choice < 1
    return null
  else
    list[Math.floor(choice)-1]    

module.exports.readline = ->
  readline = require "readline"
  readline.createInterface { input: process.stdin, output: process.stdout }
