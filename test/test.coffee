emysql=require '../index'

emysql.init __dirname+'/config.json'

console.log '\n========== Pool will be killed after 5 minutes ===========\n'

console.log '\n========== Every 3 sec one conn will be killed ==========\n'

setInterval ->
    emysql.conn.end()
,3000

belog=(cb)->
    (err,rows)->
        conosle.log "Error Occured: #{JSON.stringify err}" if err?
        console.log "Data Retrived: #{JSON.stringify rows}"
        cb() if typeof cb is 'function'


emysql.conn.query 'CREATE TABLE test (id INT NOT NULL AUTO_INCREMENT,data TEXT NOT NULL,PRIMARY KEY (id))',belog ->

    emysql.conn.query 'SHOW DATABASES;',belog()

    console.log '\n========== Create 100 rows ==========\n========== And Log them out in 5 secs =========='
    for i in [1..100]
        emysql.conn.query 'INSERT INTO test SET data = ?;',['test_data,lalala'],belog()

    setTimeout ->
        emysql.conn.query 'SELECT * FROM test LIMIT 20;',belog ->
            console.log '========== Kill them all =========='
            for i in [1...20]
                try
                    emysql.conn.end()
    ,5000

setTimeout ()->
    process.exit 0
,300000
