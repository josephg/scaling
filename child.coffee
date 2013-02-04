mongo = require 'mongoskin'

db = mongo.db('localhost:27017/tx?auto_reconnect', safe:true)
collection = db.collection('things')

distributedUpdates = (done) ->
  v = 0
  sum = 0

  next = ->
    if v < 100
      iter()
    else
      console.log "sum should be #{sum}"
      done?()

  do iter = ->
    inc = Math.floor Math.random() * 100
    collection.update {_id:1, v}, {$set: {sum:sum + inc, v:v + 1}}, (err, result) ->
      throw err if err

      if result is 0
        # Someone else updated the db. GET then try again.
        process.nextTick -> collection.findOne {_id:1}, (err, result) ->
          v = result.v
          sum = result.sum
          next()

      else
        console.log "added #{inc} -> v #{v}"
        v = v + 1
        sum += inc
        next()

process.title = 'slave'
distributedUpdates -> db.close()

