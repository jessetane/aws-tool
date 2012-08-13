#
#
#

util = require "../util/util"

#
#
#
proxyTest = ->
  data = { x: { y: { z: 41 }}}

  class Test
    util.proxy @, "universe", "data", "x", "y", "z"
    constructor: (data) ->
      @data = data
    print: =>
      console.log @data
  
  t = new Test data
  t.print()
  console.log t.universe
  t.universe = 42
  console.log t.universe
  t.print()


#
#
#
proxyTest()
