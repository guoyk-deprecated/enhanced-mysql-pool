emysql=require '../index'

emysql.init __dirname+'/config.json'

emysql.conn.query 'SHOW DATABASES;',(err,rows)->
    throw err if err?
    console.log "Show databases: #{JSON.stringify rows}"
