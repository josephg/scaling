mongo = require 'mongoskin'
child_process = require 'child_process'

db = mongo.db('localhost:27017/tx?auto_reconnect', safe:true)
collection = db.collection('things')
process.title = 'master'

num = +process.argv[2] or 1
collection.save {_id:1, v:0, foo:'bar', sum: 0}, (err, k) ->
  db.close()

  workers = new Array num
  work = 10000 / num
  workersReady = 0
  workersComplete = 0
  start = 0

  for i in [0...workers.length]
    workers[i] = cp = child_process.fork './child'
    cp.on 'message', (m) ->
      if m is 'ready'
        workersReady++
        if workersReady == workers.length
          console.log "All #{workers.length} workers ready"

          # Wait for things to settle...
          setTimeout ->
            start = Date.now()
            w.send work for w in workers
          , 1000

      if m is 'done'
        workersComplete++

        if workersComplete == workers.length
          secs = (Date.now() - start)/1000
          total = work * workers.length
          console.log "Took #{workers.length} workers #{secs} seconds to do #{total}: #{Math.floor total/secs} tps"

          w.disconnect() for w in workers

