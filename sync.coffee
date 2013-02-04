# This is a synchronously updating equivalent of test.coffee.

mongo = require 'mongoskin'
db = mongo.db('localhost:27017/tx?auto_reconnect', safe:true)
collection = db.collection('things')


syncUpdates = (count, done) ->
  sum = 0

  tryUpdate = ->
    inc = Math.floor Math.random() * 100
    process.nextTick -> collection.update {_id:1}, {$set: {sum}}, (err, result) ->
      throw err if err
      throw new Error 'did not find value to update' unless result is 1

      sum += inc
      count--
      next()

  do next = ->
    if count > 0
      tryUpdate()
    else
      console.log "sum should be #{sum}"
      done?()


start = Date.now()
syncUpdates 10000, ->
  secs = (Date.now() - start) / 1000
  total = 10000
  console.log "Took #{secs} seconds to do #{total}: #{Math.floor total/secs} tps"

  db.close()
