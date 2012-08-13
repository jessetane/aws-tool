#
# cache
#

fs = require "fs"

module.exports = class Cache
  
  #
  load: (cb) =>
    fs.readFile ".awscache", "utf8", (err, data) =>
      if not err
        try
          data = JSON.parse data
          @[key] = value for key, value of data
        catch parseErr
          err = parseErr
      cb err, data
  
  #
  save: (cb) =>
    string = JSON.stringify @
    fs.writeFile ".awscache", string, cb