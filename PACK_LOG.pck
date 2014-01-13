CREATE OR REPLACE PACKAGE PACK_LOG AS

  START_STEP CONSTANT DB_LOG.STEP_NO%TYPE := '0';  --��ʼ����
  END_STEP   CONSTANT DB_LOG.STEP_NO%TYPE := '-1'; --��������

  START_MSG  CONSTANT VARCHAR2(10) := '��ʼ��'; --��ʼ��Ϣ
  END_MSG    CONSTANT VARCHAR2(10) := '������'; --������Ϣ

  DEBUG_LEVEL CONSTANT DB_LOG.LOG_LEVEL%TYPE := '2'; --�������
  INFO_LEVEL  CONSTANT DB_LOG.LOG_LEVEL%TYPE := '3'; --�������
  WARN_LEVEL  CONSTANT DB_LOG.LOG_LEVEL%TYPE := '4'; --���ݴ��󣬿�Ԥ֪����
  ERR_LEVEL   CONSTANT DB_LOG.LOG_LEVEL%TYPE := '5'; --�쳣����δ֪����

  PROCEDURE LOG(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- �洢������
                IN_STEPNO   IN DB_LOG.STEP_NO%TYPE,   -- ������
                IN_INFO     IN DB_LOG.INFO%TYPE,      -- ��־����
                IN_LEVEL    IN DB_LOG.LOG_LEVEL%TYPE);-- ����

  PROCEDURE DEBUG(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- �洢������
                  IN_STEPNO   IN DB_LOG.STEP_NO%TYPE, -- ������
                  IN_INFO     IN DB_LOG.INFO%TYPE); --��־����

  PROCEDURE INFO(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- �洢������
                 IN_STEPNO   IN DB_LOG.STEP_NO%TYPE, -- ������
                 IN_INFO     IN DB_LOG.INFO%TYPE); --��־����

  PROCEDURE WARN(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- �洢������
                 IN_STEPNO   IN DB_LOG.STEP_NO%TYPE, -- ������
                 IN_INFO     IN DB_LOG.INFO%TYPE); --��־����

  PROCEDURE ERROR(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- �洢������
                 IN_STEPNO   IN DB_LOG.STEP_NO%TYPE, -- ������
                 IN_INFO     IN DB_LOG.INFO%TYPE); --��־����

END;
/
CREATE OR REPLACE PACKAGE BODY PACK_LOG AS
  LOG_LEVEL_FILTER  DB_LOG.LOG_LEVEL%TYPE := '3';

  LOGGING_EXCEPTION EXCEPTION;

  PROCEDURE LOG(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- �洢������
                IN_STEPNO   IN DB_LOG.STEP_NO%TYPE, -- ������
                IN_INFO     IN DB_LOG.INFO%TYPE, --��־����
                IN_LEVEL    IN DB_LOG.LOG_LEVEL%TYPE -- ����
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

  --������־
  PROCEDURE DEBUG(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- �洢������
                  IN_STEPNO   IN DB_LOG.STEP_NO%TYPE, -- ������
                  IN_INFO     IN DB_LOG.INFO%TYPE --��־����
                  ) IS
  BEGIN
    PACK_LOG.LOG(IN_PROCNAME,
                 IN_STEPNO,
                 IN_INFO,
                 PACK_LOG.DEBUG_LEVEL);
  END;

  --������־
  PROCEDURE INFO(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- �洢������
                 IN_STEPNO   IN DB_LOG.STEP_NO%TYPE, -- ������
                 IN_INFO     IN DB_LOG.INFO%TYPE --��־����
                 ) IS
  BEGIN
    PACK_LOG.LOG(IN_PROCNAME,
                 IN_STEPNO,
                 IN_INFO,
                 PACK_LOG.INFO_LEVEL);
  END;

  --������־
  PROCEDURE WARN(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- �洢������
                 IN_STEPNO   IN DB_LOG.STEP_NO%TYPE, -- ������
                 IN_INFO     IN DB_LOG.INFO%TYPE --��־����
                 ) IS
  BEGIN
    PACK_LOG.LOG(IN_PROCNAME,
                 IN_STEPNO,
                 IN_INFO,
                 PACK_LOG.WARN_LEVEL);
  END;

  --������־
  PROCEDURE ERROR(IN_PROCNAME IN DB_LOG.PROC_NAME%TYPE, -- �洢������
                 IN_STEPNO   IN DB_LOG.STEP_NO%TYPE, -- ������
                 IN_INFO     IN DB_LOG.INFO%TYPE --��־����
                 ) IS
  BEGIN
    PACK_LOG.LOG(IN_PROCNAME,
                 IN_STEPNO,
                 IN_INFO,
                 PACK_LOG.ERR_LEVEL);
  END;
END PACK_LOG;
/
