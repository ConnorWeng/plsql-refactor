create or replace type invest_term as object
(
  invest_id   varchar2(6),
  invest_time varchar2(10),
  member PROCEDURE PROC_DEAL_POP,
  member PROCEDURE create_results,
  member PROCEDURE update_quotient_remain
)
/
create or replace type body invest_term is
  member PROCEDURE PROC_DEAL_POP IS
  BEGIN
    create_results;

    update_quotient_remain;
  END;

  member PROCEDURE create_results is
  begin
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
  end;

  member PROCEDURE update_quotient_remain is
  begin
    MERGE INTO DEMO_INVEST_POP_TMP A
    USING DEMO_INVEST_POP_RESULT_TMP B
    ON (A.EMP_ID = B.EMP_ID AND A.SUBJECT_TYPE = B.SUBJECT_TYPE AND A.CO_ID = B.CO_ID AND B.INVEST_TIME = self.invest_time)
    WHEN MATCHED THEN
      UPDATE SET A.quotient_remain = A.quotient_remain - B.quotient;
  end;

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
