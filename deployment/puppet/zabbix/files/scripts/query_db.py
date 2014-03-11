#!/usr/bin/python
import ConfigParser
import sys
import logging
import sqlalchemy


CONF_FILE = '/etc/zabbix/check_db.conf'
LOGGING_LEVELS = {
    'CRITICAL': logging.CRITICAL,
    'WARNING': logging.WARNING,
    'INFO': logging.INFO,
    'DEBUG': logging.DEBUG
}

def get_logger(level):
    logger = logging.getLogger()
    ch = logging.StreamHandler(sys.stdout)
    logger.setLevel(LOGGING_LEVELS[level])
    logger.addHandler(ch)
    return logger

def query_db(logger, connection_string, query_string):
    try:
        engine = sqlalchemy.create_engine(connection_string)
        res = engine.execute(query_string).first()
    except sqlalchemy.exc.OperationalError as e:
        logger.critical("Operational error '%s'" % e)
    except sqlalchemy.exc.ProgrammingError as e:
        logger.critical("Programming error '%s'" % e)
    else:
        return res[0]

config = ConfigParser.RawConfigParser()
config.read(CONF_FILE)

logger = get_logger(config.get('query_db', 'log_level'))

if __name__ == '__main__':
    if len(sys.argv) < 2:
        logger.critical('No argvs, dunno what to do')
        sys.exit(1)

    item = sys.argv[1]
    try:
        sql_connection = config.get('query_db', '%s_connection' % item)
        sql_query = config.get('query_db', '%s_query' % item)
    except ConfigParser.NoOptionError as e:
        logger.critical("Item '%s' not configured" % item)
        sys.exit(2)

    logger.info("Get request for item '%s'" % item)
    logger.debug("Sql connection: '%s', sql query: '%s'" % (sql_connection, sql_query))
    logger.critical(query_db(logger, sql_connection, sql_query))
