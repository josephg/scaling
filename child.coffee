mongo = require 'mongoskin'

db = mongo.db('localhost:27017/tx?auto_reconnect', safe:false)
collection = db.collection('things')

distributedUpdates = (count, done) ->
  v = 0
  sum = 0

  tryUpdate = ->
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
        #console.log "added #{inc} -> v #{v}"
        sum += inc
        v++
        count--
        next()

  do next = ->
    if count > 0
      tryUpdate()
    else
      #console.log "sum should be #{sum}"
      done?()


process.title = 'slave'

process.send 'ready'
process.on 'message', (m) ->
  distributedUpdates m, ->
    process.send 'done'
    db.close()
