emysql=require '../index'

emysql.init __dirname+'/config.json'

console.log ' ============ Pool will be killed after 5 minutes ==========='

belog=(cb)->
    (err,rows)->
        conosle.log "Error Occured: #{JSON.stringify err}" if err?
        console.log "Data Retrived: #{JSON.stringify rows}"
        cb() if typeof cb is 'function'

emysql.conn.query 'SHOW DATABASES;',belog()

emysql.conn.query 'CREATE TABLE test (id INT NOT NULL AUTO_INCREMENT,data TEXT NOT NULL,PRIMARY KEY (id))',belog ->

    console.log 'Creating 20 rows ...\n And Log them out in 5 secs'
    for i in [1..20]
        emysql.conn.query 'INSERT INTO test SET data = ?;',['test_data,lalala'],belog()

    setTimeout ->
        emysql.conn.query 'SELECT * FROM test LIMIT 20;',belog()
    ,5000

setTimeout ()->
    process.exit 0
,180000
