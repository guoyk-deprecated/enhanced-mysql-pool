#MySQL
mysql = require 'mysql'

#Logger
log=require 'winston'

#Path to Config File
thefile=null

#Config
config = null

#Flag
closing = false ; retryTimer = null

max_conn = 10
max_fail = 20
retryInterval = 5000

#Count
fail_count = 0

#Connection Pool
conns = []


#Keep Connection
keepconn = (conn)->
    conn.on 'error',resume
    conn.on 'end',resume
    conn._protocol.on 'handshake',()->
        log.info 'MySQL Connection Established: '+conn._index
        fail_count = 0
        if retryTimer?
            log.info '**********  eMySQL pool Failsafe Mode Exited   **********'
            clearInterval retryTimer
            retryTimer = null

#Resume Function
resume = (err)->
    return if closing or retryTimer?
    log.error err if err?
    log.error 'MySQL Connection Failure Captured'
    fail_count++
    if fail_count > max_fail then dofailsafe() else doresume()

#DoResume Function
doresume = ()->
    conns.forEach (conn,i)->
        if conn.state is 'disconnected'
            log.info 'Resuming MySQL Connection: '+conn._index
            tmp = mysql.createConnection config
            tmp._index=i+1
            keepconn tmp
            tmp.connect()
            conns[i] = tmp

#DoResume With Reload
doresumeWR=()->
    cfgfilename = require.resolve thefile
    delete require.cache[cfgfilename]
    config=require thefile
    doresume()

#Failsafe Mode
dofailsafe = ()->
    log.error '**********    MySQL Pool Module Failed    ***********'
    log.error '   -------      Failsafe Mode Entered     ------   '
    retryTimer = setInterval doresumeWR,retryInterval

#The Connection to Provide
_r = 0

r = ()->
    if _r is max_conn-1
        _r=0
    else
        _r++
    _r

#Provide a connection
what = module.exports = ()->
    throw new Error 'Call init first' unless thefile? and config?
    conns[r()]

#Provide a connection by Property
Object.defineProperty what,'conn',
    get:()->
        throw new Error 'Call init first' unless thefile? and config?
        conns[r()]

#Provide a close method
what.close=()->
    closing = true
    clearInterval retryTimer if retryTimer?
    log.info 'eMySQL Pool is Shutting Down'
    for conn in conns
        try
            conn.end() if conn.state is not 'disconnected'
        catch ex
            log.error ex

what.setLogger=(newlogger)->
    log=newlogger

#Initilize
what.init=(file)->
    thefile=file
    config=require thefile
    max_conn = config.max_conn or 10
    max_fail = config.max_fail or 20
    retryInterval = config.retryInterval or 5000
    log.info 'Initializing eMySQL Pool...'
    for i in [1..max_conn]
        log.info "Creating MySQL Connection #{i}/#{max_conn}"
        tmp = mysql.createConnection config
        tmp._index=i
        keepconn tmp
        tmp.connect()
        conns[i-1] = tmp
    log.info 'eMySQL Pool Initialization Finished'
