create or replace type ex_prod_info under prod_info
(
  red_invest_time varchar2(10),
  constructor function ex_prod_info(I_INVEST_ID IN VARCHAR2)
    return self as result,
  member procedure PROC_INIT_OPDATE_REL,
  member FUNCTION FUNC_EXIST_QUOTIENT_REMAIN RETURN BOOLEAN,
  member function FUNC_DEAL_POP_TO_TERM_SUCCESS return boolean,
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

  member procedure PROC_INIT_OPDATE_REL IS
  begin
    DELETE FROM DEMO_OP_CO;
    INSERT INTO DEMO_OP_CO
      (OP_DATE, CO_ID)
      SELECT distinct T1.INVEST_TIME, T1.CO_ID
        FROM v_invest_term_acct_emp_and_co T1
       WHERE (T1.EMP_ID, t1.co_id, T1.SUBJECT_TYPE) IN
             (SELECT EMP_ID, co_id, SUBJECT_TYPE FROM DEMO_INVEST_POP_TMP)
         AND T1.INVEST_ID = self.invest_id
         AND PKG_DEMO.FUNC_GET_RED_ABLE(invest_id, red_invest_time, T1.INVEST_TIME) = 0;
  end;

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

  member function FUNC_DEAL_POP_TO_TERM_SUCCESS return boolean IS
    v_invest_term invest_term;
  BEGIN
    FOR RS IN (SELECT T1.OP_DATE INVEST_TIME
                 FROM DEMO_OP_CO T1
                ORDER BY PKG_DEMO.FUNC_GET_RED_PRIORITY(invest_id, T1.OP_DATE, red_invest_time) DESC) LOOP

      v_invest_term := invest_term(self.invest_id, rs.invest_time);
      v_invest_term.PROC_DEAL_POP;

      if NOT self.FUNC_EXIST_QUOTIENT_REMAIN then
        return TRUE;
      end if;
    END LOOP;

    return FALSE;
  END;
  
  member PROCEDURE PROC_DEAL_POP_TO_APPL IS
    V_REDABLE_TERM_AMT       NUMBER(17, 2);
    v_invest_appl            invest_appl;
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
        v_invest_appl      := invest_appl(rs1.co_Id,
                                          rs1.invest_time,
                                          rs1.appl_num,
                                          rs1.amt,
                                          rs1.red_amt);
        V_REDABLE_TERM_AMT := v_invest_appl.FUNC_SPLIT_TERM_AMT_TO_APPL(V_REDABLE_TERM_AMT,RS.EMP_ID,RS.SUBJECT_TYPE);
        
      END LOOP;
    END LOOP;

    DELETE FROM DEMO_INVEST_POP_RESULT_TMP WHERE YAPPL_NUM IS NULL;

  END;

  overriding member PROCEDURE PROC_DEAL_POP(o_flag in out number,
                                            o_msg  in out varchar2) is
    V_MSG VARCHAR2(4000) := NULL;
  begin
    if self.red_invest_time is null then
      self.PROC_SET_O_FLAG_AND_O_MSG(2,
                                     '无法获取下一次赎回集中确认日',
                                     O_FLAG,
                                     O_MSG);
      RETURN;
    end if;

    self.PROC_INIT_AND_CLEANUP;

    self.PROC_INIT_OPDATE_REL;

    IF NOT self.FUNC_DEAL_POP_TO_TERM_SUCCESS THEN
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
    MAX_APPL_NUM CONSTANT NUMBER := 5;
  BEGIN

    BEGIN
      SELECT EMP_ID, CO_ID, CNT
        INTO V_EMP_ID, V_CO_ID, V_COUNT
        FROM (SELECT EMP_ID, CO_ID, SUBJECT_TYPE, COUNT(1) CNT
                FROM DEMO_INVEST_POP_RESULT_TMP
               GROUP BY EMP_ID, CO_ID, SUBJECT_TYPE
              HAVING COUNT(1) > MAX_APPL_NUM)
       WHERE ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
    END;

    SELECT DECODE(V_EMP_ID,
                  'FFFFFFFFFF',
                  '企业：' || PKG_DEMO_COMMON.FUNC_GET_COFNAMEBYID(V_CO_ID),
                  '员工：' || V_EMP_ID) || '生成申请单超过' || MAX_APPL_NUM || '条'
      INTO V_MSG
      FROM DUAL;

    RETURN V_COUNT > 0;

  END;
end;
/
