create or replace type invest_term as object
(
  invest_id   varchar2(6),
  invest_time varchar2(10),
  member PROCEDURE PROC_DEAL_POP_EX_TO_TERM,
  member FUNCTION FUNC_IS_TOTAL_TO_TERM_DONE RETURN BOOLEAN,
  member FUNCTION FUNC_EXIST_QUOTIENT_REMAIN RETURN BOOLEAN

)
/
create or replace type body invest_term is
  member PROCEDURE PROC_DEAL_POP_EX_TO_TERM IS
  
  BEGIN
    INSERT INTO DEMO_INVEST_POP_RESULT_TMP
      (EMP_ID, CO_ID, SUBJECT_TYPE, INVEST_TIME, AMT, QUOTIENT)
      SELECT T1.EMP_ID,
             T1.CO_ID,
             T1.SUBJECT_TYPE,
             T2.INVEST_TIME,
             LEAST(T1.quotient_remain, T2.AMT),
             LEAST(T1.quotient_remain, T2.AMT)
        FROM DEMO_INVEST_POP_TMP T1, v_invest_term_acct_emp_and_co T2
       WHERE T1.EMP_ID = T2.EMP_ID
         AND T1.SUBJECT_TYPE = T2.SUBJECT_TYPE
         AND T2.INVEST_ID = self.invest_id
         AND T2.INVEST_TIME = self.invest_time
         AND T1.quotient_remain > 0;
  
  END;
  member FUNCTION FUNC_IS_TOTAL_TO_TERM_DONE RETURN BOOLEAN IS
  BEGIN
    MERGE INTO DEMO_INVEST_POP_TMP A
    USING DEMO_INVEST_POP_RESULT_TMP B
    ON (A.EMP_ID = B.EMP_ID AND A.SUBJECT_TYPE = B.SUBJECT_TYPE AND A.CO_ID = B.CO_ID AND B.INVEST_TIME = self.invest_time)
    WHEN MATCHED THEN
      UPDATE SET A.quotient_remain = A.quotient_remain - B.quotient;
  
    RETURN NOT FUNC_EXIST_QUOTIENT_REMAIN;
  END;
  member FUNCTION FUNC_EXIST_QUOTIENT_REMAIN RETURN BOOLEAN IS
    V_COUNT NUMBER;
  BEGIN
    SELECT COUNT(1)
      INTO V_COUNT
      FROM DEMO_INVEST_POP_TMP
     WHERE quotient_remain > 0
       AND ROWNUM = 1;
    RETURN V_COUNT > 0;
  END;

end;
/
