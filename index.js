var closing, config, conns, dofailsafe, doresume, doresumeWR, fail_count, keepconn, log, max_conn, max_fail, mysql, r, resume, retryInterval, retryTimer, thefile, what, _r;

mysql = require('mysql');

log = require('winston');

thefile = null;

config = null;

closing = false;

retryTimer = null;

max_conn = 10;

max_fail = 20;

retryInterval = 5000;

fail_count = 0;

conns = [];

keepconn = function(conn) {
  conn.on('error', resume);
  conn.on('end', resume);
  return conn.on('connection', function() {
    log.info('A New MySQL Connection Established');
    fail_count = 0;
    if (retryTimer != null) {
      log.info('MySQL-pool Failsafe Mode Exited');
      clearInterval(retryTimer);
      return retryTimer = null;
    }
  });
};

resume = function(err) {
  if (closing || (retryTimer != null)) {
    return;
  }
  if (err != null) {
    log.error(err);
  }
  log.error('MySQL Connection Failure Captured');
  fail_count++;
  if (fail_count > max_fail) {
    return dofailsafe();
  } else {
    return doresume();
  }
};

doresume = function() {
  return conns.forEach(function(conn, i) {
    var tmp;
    if (conn.state === 'disconnected') {
      log.info('Resuming a MySQL Connection');
      tmp = mysql.createConnection(config);
      keepconn(tmp);
      tmp.connect();
      return conns[i] = tmp;
    }
  });
};

doresumeWR = function() {
  var cfgfilename;
  cfgfilename = require.resolve(thefile);
  delete require.cache[cfgfilename];
  config = require(thefile);
  return doresume();
};

dofailsafe = function() {
  log.error('******    MySQL Pool Module Failed   ******');
  log.error('   ---      Failsafe Mode Entered    ---   ');
  return retryTimer = setInterval(doresumeWR, retryInterval);
};

_r = 0;

r = function() {
  if (_r === max_conn - 1) {
    _r = 0;
  } else {
    _r++;
  }
  return _r;
};

what = module.exports = function() {
  if (!((thefile != null) && (config != null))) {
    throw new Error('Call init first');
  }
  return conns[r()];
};

Object.defineProperty(what, 'conn', {
  get: function() {
    if (!((thefile != null) && (config != null))) {
      throw new Error('Call init first');
    }
    return conns[r()];
  }
});

what.close = function() {
  var conn, ex, _i, _len, _results;
  closing = true;
  if (retryTimer != null) {
    clearInterval(retryTimer);
  }
  log.info('MySQL Pool is Shutting Down');
  _results = [];
  for (_i = 0, _len = conns.length; _i < _len; _i++) {
    conn = conns[_i];
    try {
      if (conn.state === !'disconnected') {
        _results.push(conn.end());
      } else {
        _results.push(void 0);
      }
    } catch (_error) {
      ex = _error;
      _results.push(log.error(ex));
    }
  }
  return _results;
};

what.setLogger = function(newlogger) {
  return log = newlogger;
};

what.init = function(file) {
  var i, tmp, _i;
  thefile = file;
  config = require(thefile);
  max_conn = config.max_conn || 10;
  max_fail = config.max_fail || 20;
  retryInterval = config.retryInterval || 5000;
  log.info('Initializing MySQL Pool...');
  for (i = _i = 1; 1 <= max_conn ? _i <= max_conn : _i >= max_conn; i = 1 <= max_conn ? ++_i : --_i) {
    log.info("Creating MySQL Connection " + i + "/" + max_conn);
    tmp = mysql.createConnection(config);
    keepconn(tmp);
    tmp.connect();
    conns[i - 1] = tmp;
  }
  return console.info(' MySQL Pool Initialization Finished');
};
