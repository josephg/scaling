mongo = require 'mongoskin'
child_process = require 'child_process'

db = mongo.db('localhost:27017/tx?auto_reconnect', safe:true)
collection = db.collection('things')

syncUpdates = (done) ->
  v = 0
  sum = 0

  next = ->
    if v < 100
      process.nextTick iter
    else
      console.log "sum should be #{sum}"
      done?()

  iter = ->
    inc = Math.floor Math.random() * 100
    sum += inc
    console.log sum, v
    collection.update {_id:1}, {$set: {sum}}, (err, result) ->
      v++
      throw err if err
      throw new Error 'did not find value to update' unless result is 1
      next()

  iter()

process.title = 'master'
collection.save {_id:1, v:0, foo:'bar', sum: 0}, (err, k) ->
  db.close()
  for i in [1..100]
    cp = child_process.fork './child'
    cp.disconnect()

