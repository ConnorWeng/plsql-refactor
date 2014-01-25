create or replace type unex_prod_info under prod_info
(
  constructor function unex_prod_info(I_INVEST_ID IN VARCHAR2)
    return self as result,
  member FUNCTION FUNC_GET_DONE_OP_DATE RETURN VARCHAR2,
  member FUNCTION FUNC_NOT_EXIST_DONE_OP_DATE RETURN BOOLEAN,
  overriding member PROCEDURE PROC_DEAL_POP(o_flag in out number,
                                            o_msg  in out varchar2),
  member function FUNC_GET_REDABLE_QUOTIENT(I_QUOTIENT_REMAIN IN NUMBER,
                                            I_QUOTIENT        IN NUMBER)
    RETURN NUMBER,
  member function FUNC_GET_REDABLE_AMT(I_QUOTIENT_REMAIN IN NUMBER,
                                       I_QUOTIENT        IN NUMBER,
                                       I_AMT             IN NUMBER)
    RETURN NUMBER,
  member PROCEDURE PROC_DEAL_POP_UNEX_EMP_AND_CO

)
/
create or replace type body unex_prod_info is
  constructor function unex_prod_info(I_INVEST_ID IN VARCHAR2)
    return self as result is
  begin
    PROC_NAME                     := 'PROC_DEAL_POP';
    EVAL_STATE_FLAG_RECENT_TRADED := 2;
    self.invest_id                := i_invest_id;
    return;
  end;
  member FUNCTION FUNC_GET_DONE_OP_DATE RETURN VARCHAR2 IS
    V_DONE_OP_DATE VARCHAR2(10);
  BEGIN
    SELECT EVALUATE_DATE
      INTO V_DONE_OP_DATE
      FROM DEMO_INVEST_UNIT_VALUE
     WHERE INVEST_ID = self.invest_id
       AND EVAL_STATE_FLAG = EVAL_STATE_FLAG_RECENT_TRADED;
    RETURN V_DONE_OP_DATE;
  exception
    when NO_DATA_FOUND THEN
      return null;
  END;

  member FUNCTION FUNC_NOT_EXIST_DONE_OP_DATE RETURN BOOLEAN IS
    v_done_op_date varchar2(10) := FUNC_GET_DONE_OP_DATE;
  BEGIN
    return v_done_op_date is null;
  END;

  overriding member PROCEDURE PROC_DEAL_POP(o_flag in out number,
                                            o_msg  in out varchar2) is
  begin
    self.PROC_INIT_AND_CLEANUP;
    IF FUNC_NOT_EXIST_DONE_OP_DATE THEN
      self.PROC_SET_O_FLAG_AND_O_MSG(2,
                                     '系统中不存在已完成的集中确认日，无法进行后续操作！',
                                     O_FLAG,
                                     O_MSG);
      RETURN;
    END IF;
  
    PROC_DEAL_POP_UNEX_EMP_AND_CO;
  
    IF self.FUNC_IS_RED_TOTAL_AMT_NOTEQ THEN
      self.PROC_SET_O_FLAG_AND_O_MSG(2,
                                     '赎回份额分配出错！',
                                     O_FLAG,
                                     O_MSG);
      RETURN;
    END IF;
  end;
  member function FUNC_GET_REDABLE_QUOTIENT(I_QUOTIENT_REMAIN IN NUMBER,
                                            I_QUOTIENT        IN NUMBER)
    RETURN NUMBER IS
  
  BEGIN
    RETURN LEAST(I_QUOTIENT_REMAIN, I_QUOTIENT);
  END;

  member function FUNC_GET_REDABLE_AMT(I_QUOTIENT_REMAIN IN NUMBER,
                                       I_QUOTIENT        IN NUMBER,
                                       I_AMT             IN NUMBER)
    RETURN NUMBER IS
  
  BEGIN
    RETURN FUNC_GET_REDABLE_QUOTIENT(I_QUOTIENT_REMAIN, I_QUOTIENT) / I_QUOTIENT * I_AMT;
  END;
  member PROCEDURE PROC_DEAL_POP_UNEX_EMP_AND_CO IS
  BEGIN
    INSERT INTO DEMO_INVEST_POP_RESULT_TMP
      (EMP_ID, CO_ID, SUBJECT_TYPE, INVEST_TIME, AMT, QUOTIENT)
      with EMP_CO_INVEST_ACCT as
       (SELECT EMP_ID, CO_ID, INVEST_ID, SUBJECT_TYPE, QUOTIENT, AMT
          FROM DEMO_EMP_INVEST
         WHERE quotient > 0
        UNION
        SELECT 'FFFFFFFFFF' EMP_ID,
               CO_ID,
               INVEST_ID,
               SUBJECT_TYPE,
               QUOTIENT,
               AMT
          FROM DEMO_CO_INVEST
         WHERE quotient > 0)
      SELECT T1.EMP_ID,
             T1.CO_ID,
             T1.SUBJECT_TYPE,
             self.FUNC_GET_DONE_OP_DATE,
             self.FUNC_GET_REDABLE_AMT(T1.quotient_remain,
                                       T2.quotient,
                                       T2.AMT),
             self.FUNC_GET_REDABLE_QUOTIENT(T1.quotient_remain, T2.quotient)
        FROM DEMO_INVEST_POP_TMP T1, EMP_CO_INVEST_ACCT T2
       WHERE T1.EMP_ID = T2.EMP_ID
         AND T1.SUBJECT_TYPE = T2.SUBJECT_TYPE
         AND T2.INVEST_ID = self.invest_id
         AND T1.quotient_remain > 0;
  
  END;

end;
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
