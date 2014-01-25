create or replace type ex_prod_info under prod_info
(
  red_invest_time varchar2(10),
  constructor function ex_prod_info(I_INVEST_ID IN VARCHAR2)
    return self as result,
  member procedure PROC_EX_INIT_OPDATE_REL,
  member PROCEDURE PROC_DEAL_POP_EX_TO_TERM(I_INVEST_TIME IN VARCHAR2),
  member FUNCTION FUNC_EXIST_QUOTIENT_REMAIN RETURN BOOLEAN,
  member FUNCTION FUNC_IS_TOTAL_TO_TERM_DONE(I_INVEST_TIME IN VARCHAR2)
    RETURN BOOLEAN,
  member function FUNC_GET_REDABLE_APPL_AMT(I_CO_ID       IN VARCHAR2,
                                            I_INVEST_TIME IN VARCHAR2,
                                            I_APPL_NUM    IN NUMBER,
                                            I_AMT         IN NUMBER,
                                            I_REDABLE_AMT IN NUMBER)
    RETURN NUMBER,
  member PROCEDURE PROC_DEAL_POP_EX_TERM_TO_APPL(I_EMP_ID                 IN VARCHAR2,
                                                 I_CO_ID                  IN VARCHAR2,
                                                 I_SUBJECT_TYPE           IN VARCHAR2,
                                                 I_INVEST_TIME            IN VARCHAR2,
                                                 I_APPL_NUM               IN NUMBER,
                                                 I_DEAL_POP_DONE_APPL_AMT IN NUMBER),
  member procedure PROC_DEAL_POP_TO_TERM,
  member PROCEDURE PROC_DEAL_POP_TO_APPL,
  overriding member PROCEDURE PROC_DEAL_POP(o_flag in out number,
                                            o_msg  in out varchar2),
  member function FUNC_GET_PLAN_ID_BY_INVEST_ID return varchar2,
  member function FUNC_GET_NEXT_RED_TIME RETURN VARCHAR2,
  member FUNCTION FUNC_IS_APPL_MORE_THEN_FIVE(V_MSG OUT VARCHAR2)
    RETURN BOOLEAN
)
/
create or replace type body ex_prod_info is
  constructor function ex_prod_info(I_INVEST_ID IN VARCHAR2)
    return self as result is
  begin
    PROC_NAME                     := 'PROC_DEAL_POP';
    EVAL_STATE_FLAG_RECENT_TRADED := 2;
    self.invest_id                := i_invest_id;
    self.red_invest_time          := self.FUNC_GET_NEXT_RED_TIME;
    return;
  end;

  member procedure PROC_EX_INIT_OPDATE_REL IS
  begin
    DELETE FROM DEMO_OP_CO;
    INSERT INTO DEMO_OP_CO
      (OP_DATE, CO_ID)
      SELECT distinct T1.INVEST_TIME, T1.CO_ID
        FROM v_invest_term_acct_emp_and_co T1
       WHERE (T1.EMP_ID,t1.co_id, T1.SUBJECT_TYPE) IN
             (SELECT EMP_ID,co_id, SUBJECT_TYPE
                FROM DEMO_INVEST_POP_TMP)
         AND T1.INVEST_ID = self.invest_id
         AND PKG_DEMO.FUNC_GET_RED_ABLE(invest_id, red_invest_time, T1.INVEST_TIME) = 0;
  end;

  member PROCEDURE PROC_DEAL_POP_EX_TO_TERM(I_INVEST_TIME IN VARCHAR2) IS
  
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
         AND T2.INVEST_TIME = I_INVEST_TIME
         AND T1.quotient_remain > 0;
  
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

  member FUNCTION FUNC_IS_TOTAL_TO_TERM_DONE(I_INVEST_TIME IN VARCHAR2)
    RETURN BOOLEAN IS
  BEGIN
    MERGE INTO DEMO_INVEST_POP_TMP A
    USING DEMO_INVEST_POP_RESULT_TMP B
    ON (A.EMP_ID = B.EMP_ID AND A.SUBJECT_TYPE = B.SUBJECT_TYPE AND A.CO_ID = B.CO_ID AND B.INVEST_TIME = I_INVEST_TIME)
    WHEN MATCHED THEN
      UPDATE SET A.quotient_remain = A.quotient_remain - B.quotient;
  
    RETURN NOT FUNC_EXIST_QUOTIENT_REMAIN;
  END;
  member function FUNC_GET_REDABLE_APPL_AMT(I_CO_ID       IN VARCHAR2,
                                            I_INVEST_TIME IN VARCHAR2,
                                            I_APPL_NUM    IN NUMBER,
                                            I_AMT         IN NUMBER,
                                            I_REDABLE_AMT IN NUMBER)
    RETURN NUMBER IS
    V_REDABLE_APPL_AMT NUMBER(17, 2);
  BEGIN
    SELECT I_AMT - NVL(I_REDABLE_AMT, 0) - NVL(SUM(T3.AMT), 0)
      INTO V_REDABLE_APPL_AMT
      FROM DEMO_INVEST_POP_RESULT_TMP T3
     WHERE T3.CO_ID = I_CO_ID
       AND T3.INVEST_TIME = I_INVEST_TIME
       AND T3.YAPPL_NUM = I_APPL_NUM;
    RETURN V_REDABLE_APPL_AMT;
  END;

  member PROCEDURE PROC_DEAL_POP_EX_TERM_TO_APPL(I_EMP_ID                 IN VARCHAR2,
                                                 I_CO_ID                  IN VARCHAR2,
                                                 I_SUBJECT_TYPE           IN VARCHAR2,
                                                 I_INVEST_TIME            IN VARCHAR2,
                                                 I_APPL_NUM               IN NUMBER,
                                                 I_DEAL_POP_DONE_APPL_AMT IN NUMBER) IS
  
  BEGIN
    INSERT INTO DEMO_INVEST_POP_RESULT_TMP
      (EMP_ID, CO_ID, SUBJECT_TYPE, INVEST_TIME, AMT, QUOTIENT, YAPPL_NUM)
    VALUES
      (I_EMP_ID,
       I_CO_ID,
       I_SUBJECT_TYPE,
       I_INVEST_TIME,
       I_DEAL_POP_DONE_APPL_AMT,
       I_DEAL_POP_DONE_APPL_AMT,
       I_APPL_NUM);
  
  END;

  member procedure PROC_DEAL_POP_TO_TERM IS
    v_invest_term invest_term; 
  BEGIN
    FOR RS IN (SELECT T1.OP_DATE INVEST_TIME
                 FROM DEMO_OP_CO T1
                ORDER BY PKG_DEMO.FUNC_GET_RED_PRIORITY(invest_id, T1.OP_DATE, red_invest_time) DESC) LOOP
    
      v_invest_term := invest_term(self.invest_id, rs.invest_time); 
      v_invest_term.PROC_DEAL_POP_EX_TO_TERM;
      
      EXIT WHEN v_invest_term.FUNC_IS_TOTAL_TO_TERM_DONE;
    END LOOP;
  
  END;

  member PROCEDURE PROC_DEAL_POP_TO_APPL IS
    V_REDABLE_TERM_AMT       NUMBER(17, 2);
    V_REDABLE_APPL_AMT       NUMBER(17, 2);
    V_DEAL_POP_DONE_APPL_AMT NUMBER(17, 2);
  BEGIN
    FOR RS IN (SELECT *
                 FROM DEMO_INVEST_POP_RESULT_TMP T1
                WHERE T1.YAPPL_NUM IS NULL) LOOP
    
      V_REDABLE_TERM_AMT := RS.AMT;
    
      FOR RS1 IN (SELECT *
                    FROM DEMO_APPL_NUM_REL T2
                   WHERE T2.CO_ID = RS.CO_ID
                     AND T2.INVEST_ID = self.invest_id
                     AND T2.INVEST_TIME = RS.INVEST_TIME
                     AND T2.AMT > 0
                     AND T2.AMT - NVL(T2.RED_AMT, 0) > 0
                   order by t2.appl_num desc) LOOP
        exit when V_REDABLE_TERM_AMT = 0;
        V_REDABLE_APPL_AMT := self.FUNC_GET_REDABLE_APPL_AMT(RS1.CO_ID,
                                                             RS1.INVEST_TIME,
                                                             RS1.APPL_NUM,
                                                             RS1.AMT,
                                                             RS1.RED_AMT);
        IF V_REDABLE_APPL_AMT > 0 THEN
          V_DEAL_POP_DONE_APPL_AMT := LEAST(V_REDABLE_TERM_AMT,
                                            V_REDABLE_APPL_AMT);
          self.PROC_DEAL_POP_EX_TERM_TO_APPL(RS.EMP_ID,
                                             RS.CO_ID,
                                             RS.SUBJECT_TYPE,
                                             RS.INVEST_TIME,
                                             RS1.APPL_NUM,
                                             V_DEAL_POP_DONE_APPL_AMT);
        
          V_REDABLE_TERM_AMT := V_REDABLE_TERM_AMT -
                                V_DEAL_POP_DONE_APPL_AMT;
        END IF;
      END LOOP;
    END LOOP;
  
    DELETE FROM DEMO_INVEST_POP_RESULT_TMP WHERE YAPPL_NUM IS NULL;
  
  END;

  overriding member PROCEDURE PROC_DEAL_POP(o_flag in out number,
                                            o_msg  in out varchar2) is
    V_MSG VARCHAR2(4000) := NULL;
  begin
    self.PROC_INIT_AND_CLEANUP;
  
    if self.red_invest_time is null then
      self.PROC_SET_O_FLAG_AND_O_MSG(2,
                                     '无法获取下一次赎回集中确认日',
                                     O_FLAG,
                                     O_MSG);
      RETURN;
    end if;
  
    self.PROC_EX_INIT_OPDATE_REL;
  
    self.PROC_DEAL_POP_TO_TERM;
  
    IF self.FUNC_EXIST_QUOTIENT_REMAIN THEN
      self.PROC_SET_O_FLAG_AND_O_MSG(2,
                                     '进行后进先出处理时，资产不足',
                                     O_FLAG,
                                     O_MSG);
      return;
    END IF;
    
    self.PROC_DEAL_POP_TO_APPL;
  
    IF self.FUNC_IS_RED_TOTAL_AMT_NOTEQ THEN
      self.PROC_SET_O_FLAG_AND_O_MSG(2,
                                     '赎回份额分配出错',
                                     O_FLAG,
                                     O_MSG);
      return;
    END IF;
  
    IF self.FUNC_IS_APPL_MORE_THEN_FIVE(V_MSG) THEN
      self.PROC_SET_O_FLAG_AND_O_MSG(3,
                                     V_MSG,
                                     O_FLAG,
                                     O_MSG);
      return;
    END IF;
  end;
  
  member function FUNC_GET_PLAN_ID_BY_INVEST_ID return varchar2 is
    V_PLAN_ID DEMO_INVEST_INFO.Plan_Id%type;
  begin
    --获取计划编码
    SELECT PLAN_ID
      INTO V_PLAN_ID
      FROM DEMO_INVEST_INFO
     WHERE INVEST_ID = self.invest_id;
    return V_PLAN_ID;
  end;

  member function FUNC_GET_NEXT_RED_TIME RETURN VARCHAR2 IS
    RED_OP_TYPE CONSTANT NUMBER := 3;
    V_RED_INVEST_TIME DEMO_INVEST_OP_CONTROL.INVEST_TIME%TYPE;
  BEGIN
    --获取最近一次的集中确认日
    SELECT MIN(T.DEMO_INVEST_TIME)
      INTO V_RED_INVEST_TIME
      FROM V_INVEST_OP_CONTROL T
     WHERE T.INVEST_ID = self.invest_id
       AND T.OP_TYPE = RED_OP_TYPE
       AND T.DEMO_INVEST_TIME >
           PKG_DEMO_COMMON.FUNC_GET_PLANTIMEBYID(self.func_get_plan_id_by_invest_id);
    RETURN V_RED_INVEST_TIME;
  END;

  member FUNCTION FUNC_IS_APPL_MORE_THEN_FIVE(V_MSG OUT VARCHAR2)
    RETURN BOOLEAN IS
    V_COUNT  NUMBER;
    V_EMP_ID DEMO_EMP_INFO.EMP_ID%TYPE;
    V_CO_ID  DEMO_CO_INFO.CO_ID%TYPE;
  BEGIN
  
    BEGIN
      SELECT EMP_ID, CO_ID, CNT
        INTO V_EMP_ID, V_CO_ID, V_COUNT
        FROM (SELECT EMP_ID, CO_ID, SUBJECT_TYPE, COUNT(1) CNT
                FROM DEMO_INVEST_POP_RESULT_TMP
               GROUP BY EMP_ID, CO_ID, SUBJECT_TYPE
              HAVING COUNT(1) > 5)
       WHERE ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
    END;
  
    SELECT DECODE(V_EMP_ID,
                  'FFFFFFFFFF',
                  '企业：' || PKG_DEMO_COMMON.FUNC_GET_COFNAMEBYID(V_CO_ID),
                  '员工：' || V_EMP_ID) || '生成申请单超过5条'
      INTO V_MSG
      FROM DUAL;
  
    RETURN V_COUNT > 0;
  
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
