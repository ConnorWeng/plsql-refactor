CREATE OR REPLACE PACKAGE PKG_DEMO IS

  PROC_NAME                     CONSTANT DB_LOG.PROC_NAME%TYPE := 'PKG_DEMO.PROC_DEAL_POP';
  PROCEDURE PROC_DEAL_POP(I_INVEST_ID IN VARCHAR2,
                          O_FLAG      OUT NUMBER,
                          O_MSG       OUT VARCHAR2);
  FUNCTION FUNC_GET_RED_ABLE(I_INVEST_ID       IN VARCHAR2,
                             I_RED_INVEST_TIME IN VARCHAR2,
                             I_BUY_INVEST_TIME IN VARCHAR2) RETURN NUMBER;
  FUNCTION FUNC_GET_RED_PRIORITY(p_invest_id       IN VARCHAR2,
                                 p_invest_time     IN VARCHAR2,
                                 p_invest_red_time IN VARCHAR2)
    RETURN VARCHAR2;
END PKG_DEMO;
/

CREATE OR REPLACE PACKAGE BODY PKG_DEMO IS
  PROCEDURE PROC_DEAL_POP(I_INVEST_ID IN VARCHAR2,
                          O_FLAG      OUT NUMBER,
                          O_MSG       OUT VARCHAR2) IS
    v_prod_info prod_info := prod_info.create_prod_info(i_invest_id);
  BEGIN
    O_FLAG := 0;
    O_MSG  := '成功';
    v_prod_info.PROC_DEAL_POP(O_FLAG,O_MSG);
  
  EXCEPTION
    WHEN OTHERS THEN
      O_FLAG := 1;
      O_MSG  := '进行后进先出处理时异常！';
    
      PACK_LOG.LOG(PROC_NAME,
                   null,
                   O_MSG || '|' || I_INVEST_ID || '|' || SQLERRM || '|' ||
                   DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                   PACK_LOG.ERR_LEVEL);
  END PROC_DEAL_POP;

  FUNCTION FUNC_GET_RED_ABLE(I_INVEST_ID       IN VARCHAR2,
                             I_RED_INVEST_TIME IN VARCHAR2,
                             I_BUY_INVEST_TIME IN VARCHAR2) RETURN NUMBER IS
  BEGIN
    RETURN UT_PKG_DEMO_COMMON.True;
  END FUNC_GET_RED_ABLE;

  FUNCTION FUNC_GET_RED_PRIORITY(p_invest_id       IN VARCHAR2,
                                 p_invest_time     IN VARCHAR2,
                                 p_invest_red_time IN VARCHAR2)
    RETURN VARCHAR2 IS
  BEGIN
    RETURN p_invest_time;
  END FUNC_GET_RED_PRIORITY;

END PKG_DEMO;
/

set serveroutput on
/

BEGIN
  utSuite.add ('UT_PKG_DEMO_PROC_POP_DEAL');
  utPackage.add ('UT_PKG_DEMO_PROC_POP_DEAL', 'UT_PKG_DEMO_PROC_POP_DEAL_EX');
  utPackage.add ('UT_PKG_DEMO_PROC_POP_DEAL', 'UT_PKG_DEMO_PROC_POP_DEAL_UNEX');
  utPLSQL.runsuite ('UT_PKG_DEMO_PROC_POP_DEAL', per_method_setup_in => TRUE);
END;
/

select last_status from ut_suite where name = 'UT_PKG_DEMO_PROC_POP_DEAL';
