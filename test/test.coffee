emysql=require '../index'

emysql.init __dirname+'/config.json'

belog=(cb)->
    (err,rows)->
        conosle.log "Error Occured: #{JSON.stringify err,null,'\t'}" if err?
        console.log "Data Retrived: #{JSON.stringify rows,null,'\t'}"
        cb() if typeof cb is 'function'

emysql.conn.query 'SHOW DATABASES;',belog()

emysql.conn.query 'CREATE TABLE test (id INT NOT NULL,data TEXT NOT NULL,PRIMARY KEY (id))',belog ->
    setInterval ->
        emysql.conn.query 'INSERT INTO test SET data = ?;',['test_data,lalala']
    ,3000
    setInterval ->
        emysql.conn.query 'SELECT * FROM test LIMIT 20;',belog()
    ,1000

setTimeout ()->
    console.log ' ============ Pool will be killed after 3 minutes ==========='
    process.exit 0
,180000
