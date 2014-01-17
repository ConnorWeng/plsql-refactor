CREATE OR REPLACE PACKAGE PACK_LOG AS

  START_STEP CONSTANT DB_LOG.STEP_NO%TYPE := '0';  --开始步点
  END_STEP   CONSTANT DB_LOG.STEP_NO%TYPE := '-1'; --结束步点

  START_MSG  CONSTANT VARCHAR2(10) := '开始！'; --开始信息
  END_MSG    CONSTANT VARCHAR2(10) := '结束！'; --结束信息

  DEBUG_LEVEL CONSTANT DB_LOG.LOG_LEVEL%TYPE := '2'; --调试情况
  INFO_LEVEL  CONSTANT DB_LOG.LOG_LEVEL%TYPE := '3'; --正常情况
  WARN_LEVEL  CONSTANT DB_LOG.LOG_LEVEL%TYPE := '4'; --数据错误，可预知错误
  ERR_LEVEL   CONSTANT DB_LOG.LOG_LEVEL%TYPE := '5'; --异常错误，未知错误

  PROCEDURE LOG(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- 存储过程名
                IN_STEPNO   IN DB_LOG.STEP_NO%TYPE,   -- 步骤名
                IN_INFO     IN DB_LOG.INFO%TYPE,      -- 日志级别
                IN_LEVEL    IN DB_LOG.LOG_LEVEL%TYPE);-- 级别

  PROCEDURE DEBUG(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- 存储过程名
                  IN_STEPNO   IN DB_LOG.STEP_NO%TYPE, -- 步骤名
                  IN_INFO     IN DB_LOG.INFO%TYPE); --日志级别

  PROCEDURE INFO(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- 存储过程名
                 IN_STEPNO   IN DB_LOG.STEP_NO%TYPE, -- 步骤名
                 IN_INFO     IN DB_LOG.INFO%TYPE); --日志级别

  PROCEDURE WARN(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- 存储过程名
                 IN_STEPNO   IN DB_LOG.STEP_NO%TYPE, -- 步骤名
                 IN_INFO     IN DB_LOG.INFO%TYPE); --日志级别

  PROCEDURE ERROR(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- 存储过程名
                 IN_STEPNO   IN DB_LOG.STEP_NO%TYPE, -- 步骤名
                 IN_INFO     IN DB_LOG.INFO%TYPE); --日志级别

END;
/
CREATE OR REPLACE PACKAGE BODY PACK_LOG AS
  LOG_LEVEL_FILTER  DB_LOG.LOG_LEVEL%TYPE := '3';

  LOGGING_EXCEPTION EXCEPTION;

  PROCEDURE LOG(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- 存储过程名
                IN_STEPNO   IN DB_LOG.STEP_NO%TYPE, -- 步骤名
                IN_INFO     IN DB_LOG.INFO%TYPE, --日志级别
                IN_LEVEL    IN DB_LOG.LOG_LEVEL%TYPE -- 级别
                ) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    V_ERRSTACK VARCHAR2(4000):=null;
    V_ERROR_BACKTRACE VARCHAR2(4000):=null;
    V_INFO VARCHAR2(4000):=null;
  BEGIN
    IF (IN_LEVEL >= LOG_LEVEL_FILTER) THEN

      SELECT SUBSTR(DBMS_UTILITY.FORMAT_ERROR_STACK, 1, 4000)
        INTO V_ERRSTACK
        FROM DUAL;

      SELECT SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 1, 4000)
        INTO V_ERROR_BACKTRACE
        FROM DUAL;

      V_INFO := SUBSTRB(IN_INFO, 1, 4000);

      INSERT INTO DB_LOG
        (ID,
         PROC_NAME,
         INFO,
         LOG_LEVEL,
         TIME_STAMP,
         ERROR_BACKTRACE,
         ERR_STACK,
         STEP_NO,
         LOG_DATE)
      VALUES
        (LPAD(LOG_SEQ.NEXTVAL, 20, '0'),
         IN_PROCNAME,
         V_INFO,
         IN_LEVEL,
         TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS'),
         V_ERROR_BACKTRACE,
         V_ERRSTACK,
         IN_STEPNO,
         TO_CHAR(SYSDATE, 'YYYYMMDD'));
    END IF;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE LOGGING_EXCEPTION;
  END;

  --调试日志
  PROCEDURE DEBUG(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- 存储过程名
                  IN_STEPNO   IN DB_LOG.STEP_NO%TYPE, -- 步骤名
                  IN_INFO     IN DB_LOG.INFO%TYPE --日志级别
                  ) IS
  BEGIN
    PACK_LOG.LOG(IN_PROCNAME,
                 IN_STEPNO,
                 IN_INFO,
                 PACK_LOG.DEBUG_LEVEL);
  END;

  --正常日志
  PROCEDURE INFO(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- 存储过程名
                 IN_STEPNO   IN DB_LOG.STEP_NO%TYPE, -- 步骤名
                 IN_INFO     IN DB_LOG.INFO%TYPE --日志级别
                 ) IS
  BEGIN
    PACK_LOG.LOG(IN_PROCNAME,
                 IN_STEPNO,
                 IN_INFO,
                 PACK_LOG.INFO_LEVEL);
  END;

  --警告日志
  PROCEDURE WARN(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- 存储过程名
                 IN_STEPNO   IN DB_LOG.STEP_NO%TYPE, -- 步骤名
                 IN_INFO     IN DB_LOG.INFO%TYPE --日志级别
                 ) IS
  BEGIN
    PACK_LOG.LOG(IN_PROCNAME,
                 IN_STEPNO,
                 IN_INFO,
                 PACK_LOG.WARN_LEVEL);
  END;

  --错误日志
  PROCEDURE ERROR(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- 存储过程名
                 IN_STEPNO   IN DB_LOG.STEP_NO%TYPE, -- 步骤名
                 IN_INFO     IN DB_LOG.INFO%TYPE --日志级别
                 ) IS
  BEGIN
    PACK_LOG.LOG(IN_PROCNAME,
                 IN_STEPNO,
                 IN_INFO,
                 PACK_LOG.ERR_LEVEL);
  END;
END PACK_LOG;
/
