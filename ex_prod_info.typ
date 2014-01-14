create or replace type ex_prod_info under prod_info
(
-- Author  : KFZX-WANGYANG01
-- Created : 2013/12/21 12:16:07
-- Purpose : 产品

-- Attributes
  PROC_NAME                     varchar2(200),
  EVAL_STATE_FLAG_RECENT_TRADED number(1),
  constructor function ex_prod_info(I_INVEST_ID IN VARCHAR2)
    return self as result,
  member FUNCTION FUNC_GET_RED_ABLE(I_RED_INVEST_TIME IN VARCHAR2,
                                    I_BUY_INVEST_TIME IN VARCHAR2)
    RETURN NUMBER,
  member FUNCTION FUNC_GET_FULL_LCR_DATE(I_RED_DATE IN VARCHAR2)
    RETURN VARCHAR2,
  member FUNCTION FUNC_GET_RED_PRIORITY(p_invest_time     IN VARCHAR2,
                                        p_invest_red_time IN VARCHAR2)
    RETURN VARCHAR2,
  member procedure PROC_EX_INIT_CO_OPDATE_REL(I_RED_INVEST_TIME IN VARCHAR2),
  member PROCEDURE PROC_DEAL_POP_EX_TO_TERM_EMP(I_INVEST_TIME IN VARCHAR2),
  member PROCEDURE PROC_DEAL_POP_EX_TO_TERM_CO(I_INVEST_TIME IN VARCHAR2),
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
  member procedure PROC_DEAL_POP_TO_TERM(I_RED_INVEST_TIME IN VARCHAR2),
  member PROCEDURE PROC_DEAL_POP_TO_APPL,
  overriding member PROCEDURE PROC_DEAL_POP(o_flag in out number,
                                            o_msg  in out varchar2),
  member function FUNC_GET_PLAN_ID_BY_INVEST_ID return varchar2,
  member function FUNC_GET_NEXT_RED_TIME RETURN VARCHAR2,
  member PROCEDURE PROC_SET_O_FLAG_AND_O_MSG(V_FLAG   IN NUMBER,
                                             V_MSG    IN VARCHAR2,
                                             V_PARAMS IN VARCHAR2,
                                             O_FLAG   IN OUT NUMBER,
                                             O_MSG    IN OUT VARCHAR2),
  member FUNCTION FUNC_IS_RED_TOTAL_AMT_NOTEQ RETURN BOOLEAN,
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
    return;
  end;

  /*********************************************************************
    --名称:FUNC_GET_RED_ABLE
    --描述:判断是否可赎回
    --功能:判断是否可赎回
    --模块:交易管理-集中确认
    --作者:
    --时间:
    --参数:
      I_INVEST_ID       IN VARCHAR2,  投资组合代码
      I_RED_INVEST_TIME IN VARCHAR2,  赎回集中确认日
      I_BUY_INVEST_TIME IN VARCHAR2   购买集中确认日
    --返回：0，可以赎回；1，不能赎回
  *********************************************************************/
  member FUNCTION FUNC_GET_RED_ABLE(I_RED_INVEST_TIME IN VARCHAR2,
                                    I_BUY_INVEST_TIME IN VARCHAR2)
    RETURN NUMBER IS
    V_ISSUE_WAY      DEMO_INVEST_BASIC_INFO.ISSUE_WAY%TYPE;
    v_SELL_MIN_TERM  DEMO_INVEST_BASIC_INFO.Sell_Min_Term%TYPE;
    v_OPEN_SELL_TERM DEMO_INVEST_BASIC_INFO.OPEN_SELL_TERM%TYPE;
    v_max_TERM_NO    DEMO_INVEST_OP_CONTROL.term_no%TYPE;
    v_min_TERM_NO    DEMO_INVEST_OP_CONTROL.term_no%TYPE;
  
  BEGIN
    SELECT ISSUE_WAY, SELL_MIN_TERM, OPEN_SELL_TERM
      INTO V_ISSUE_WAY, v_SELL_MIN_TERM, v_OPEN_SELL_TERM
      FROM DEMO_INVEST_BASIC_INFO T
     WHERE T.INVEST_ID = self.invest_id;
  
    IF V_ISSUE_WAY = 4 THEN
      --结转型
      SELECT max(TERM_NO)
        INTO v_max_TERM_NO
        FROM v_invest_op_control t
       WHERE t.invest_id = self.invest_id
         and t.op_type in (1, 2)
         AND DEMO_INVEST_TIME = I_RED_INVEST_TIME;
    
      SELECT MAX(TERM_NO)
        INTO v_min_TERM_NO
        FROM v_invest_op_control t
       WHERE t.invest_id = self.invest_id
         and t.op_type in (1, 2)
         AND DEMO_INVEST_TIME = I_BUY_INVEST_TIME;
    
      IF v_max_TERM_NO IS NULL OR v_min_TERM_NO IS NULL THEN
        RETURN 1;
      END IF;
    
      IF MOD((v_max_TERM_NO - v_min_TERM_NO - v_SELL_MIN_TERM),
             v_OPEN_SELL_TERM) = 0 and
         v_max_TERM_NO - v_min_TERM_NO - v_SELL_MIN_TERM >= 0 THEN
        RETURN 0;
      ELSE
        RETURN 1;
      END IF;
    ELSE
      --其他
      RETURN 0;
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 1;
  END FUNC_GET_RED_ABLE;

  /*********************************************************************/
  --存储过程名称： FUNC_GET_FULL_LCR_DATE
  --存储过程描述： 根据根据赎回日期，获取对应的期满赎回日期
  --功能：         根据根据赎回日期，获取对应的期满赎回日期
  --功能模块：
  --作者：
  --时间：
  /*********************************************************************/
  member FUNCTION FUNC_GET_FULL_LCR_DATE(I_RED_DATE IN VARCHAR2)
    RETURN VARCHAR2 IS
    V_FULL_LCR_DATE VARCHAR2(10);
  BEGIN
    SELECT MAX(T.demo_invest_time)
      INTO V_FULL_LCR_DATE
      FROM V_INVEST_OP_CONTROL T
     WHERE T.INVEST_ID = self.invest_id
       AND T.OP_TYPE IN (1, 2)
       AND EXISTS (SELECT 1
              FROM V_INVEST_OP_CONTROL T1
             WHERE T1.INVEST_ID = T.INVEST_ID
               AND T1.OP_TYPE = 4
               AND T1.demo_invest_time = I_RED_DATE
               AND T1.TERM_NO = T.TERM_NO);
    RETURN V_FULL_LCR_DATE;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END FUNC_GET_FULL_LCR_DATE;
  /*********************************************************************
  --存储过程名称： PROC_GET_RED_PRIORITY
  --存储过程描述： 获取如意人生赎回期数优先级
  --功能模块：     如意人生赎回
  --作者：
  --时间：
  --参数说明：
  --p_invest_id             IN  VARCHAR2,     --投资组合编码
  --p_invest_time           IN  VARCHAR2,     --资产所在的日期
  --p_invest_red_time       IN  VARCHAR2,     --资产赎回的集中确认日
  *********************************************************************/
  member FUNCTION FUNC_GET_RED_PRIORITY(p_invest_time     IN VARCHAR2,
                                        p_invest_red_time IN VARCHAR2)
    RETURN VARCHAR2 IS
    v_full_lcr_date DEMO_INVEST_OP_CONTROL.invest_time%TYPE;
  BEGIN
    v_full_lcr_date := self.FUNC_GET_FULL_LCR_DATE(p_invest_red_time);
    IF v_full_lcr_date = self.invest_id THEN
      --这一期恰好期满，赎回采用高优先级
      RETURN '9999-12-31';
    END IF;
    RETURN p_invest_time;
  
  EXCEPTION
    WHEN OTHERS THEN
      RETURN p_invest_time;
  END FUNC_GET_RED_PRIORITY;

  member procedure PROC_EX_INIT_CO_OPDATE_REL(I_RED_INVEST_TIME IN VARCHAR2) IS
  begin
    DELETE FROM DEMO_OP_CO;
    INSERT INTO DEMO_OP_CO
      (OP_DATE, CO_ID)
      SELECT T1.INVEST_TIME, T1.CO_ID
        FROM DEMO_EMP_INVEST_TERM T1
       WHERE (T1.EMP_ID, T1.SUBJECT_TYPE) IN
             (SELECT EMP_ID, SUBJECT_TYPE
                FROM DEMO_INVEST_POP_TMP
               WHERE SUBJECT_TYPE LIKE '301%')
         AND T1.AMT > 0
         AND T1.INVEST_ID = self.invest_id
         AND self.FUNC_GET_RED_ABLE(I_RED_INVEST_TIME, T1.INVEST_TIME) = 0 --满足最低赎回期数
      UNION
      SELECT T1.INVEST_TIME, T1.CO_ID
        FROM DEMO_CO_INVEST_TERM T1
       WHERE (T1.CO_ID, T1.SUBJECT_TYPE) IN
             (SELECT CO_ID, SUBJECT_TYPE
                FROM DEMO_INVEST_POP_TMP
               WHERE SUBJECT_TYPE NOT LIKE '301%')
         AND T1.AMT > 0
         AND T1.INVEST_ID = self.invest_id
         AND self.FUNC_GET_RED_ABLE(I_RED_INVEST_TIME, T1.INVEST_TIME) = 0;
  end;

  member PROCEDURE PROC_DEAL_POP_EX_TO_TERM_EMP(I_INVEST_TIME IN VARCHAR2) IS
  
  BEGIN
    INSERT INTO DEMO_INVEST_POP_RESULT_TMP
      (EMP_ID, CO_ID, SUBJECT_TYPE, INVEST_TIME, AMT, QUOTIENT)
      SELECT T1.EMP_ID,
             T1.CO_ID,
             T1.SUBJECT_TYPE,
             T2.INVEST_TIME,
             LEAST(T1.quotient_remain, T2.AMT), --min(赎回申请金额，余额 - 待赎回金额)
             LEAST(T1.quotient_remain, T2.AMT)
        FROM DEMO_INVEST_POP_TMP T1, DEMO_EMP_INVEST_TERM T2
       WHERE T1.EMP_ID = T2.EMP_ID
         AND T1.SUBJECT_TYPE = T2.SUBJECT_TYPE
         AND T2.INVEST_ID = self.invest_id
         AND T2.INVEST_TIME = I_INVEST_TIME
         AND T2.AMT > 0
         AND T1.quotient_remain > 0
         AND T1.EMP_ID <> 'FFFFFFFFFF';
  
  END;
  member PROCEDURE PROC_DEAL_POP_EX_TO_TERM_CO(I_INVEST_TIME IN VARCHAR2) IS
  BEGIN
    --企业部分
    INSERT INTO DEMO_INVEST_POP_RESULT_TMP
      (EMP_ID, CO_ID, SUBJECT_TYPE, INVEST_TIME, AMT, QUOTIENT)
      SELECT T1.EMP_ID,
             T1.CO_ID,
             T1.SUBJECT_TYPE,
             T2.INVEST_TIME,
             LEAST(T1.quotient_remain, T2.AMT),
             LEAST(T1.quotient_remain, T2.AMT)
        FROM DEMO_INVEST_POP_TMP T1, DEMO_CO_INVEST_TERM T2
       WHERE T1.CO_ID = T2.CO_ID
         AND T1.SUBJECT_TYPE = T2.SUBJECT_TYPE
         AND T2.INVEST_ID = self.invest_id
         AND T2.INVEST_TIME = I_INVEST_TIME
         AND T2.AMT > 0
         AND T1.quotient_remain > 0
         AND T1.EMP_ID = 'FFFFFFFFFF';
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

  member procedure PROC_DEAL_POP_TO_TERM(I_RED_INVEST_TIME IN VARCHAR2) IS
  
  BEGIN
    FOR RS IN (SELECT T1.OP_DATE INVEST_TIME
                 FROM DEMO_OP_CO T1
                ORDER BY self.FUNC_GET_RED_PRIORITY(T1.OP_DATE,
                                                    I_RED_INVEST_TIME) DESC) LOOP
    
      self.PROC_DEAL_POP_EX_TO_TERM_EMP(RS.INVEST_TIME);
      self.PROC_DEAL_POP_EX_TO_TERM_CO(RS.INVEST_TIME);
    
      EXIT WHEN FUNC_IS_TOTAL_TO_TERM_DONE(RS.INVEST_TIME);
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
        --对于一期有多张申请单的情况进行倒序获取
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
  
    V_RED_INVEST_TIME DEMO_INVEST_OP_CONTROL.INVEST_TIME%TYPE := NULL;
  begin
    V_RED_INVEST_TIME := self.FUNC_GET_NEXT_RED_TIME;
  
    if V_RED_INVEST_TIME is null then
      self.PROC_SET_O_FLAG_AND_O_MSG(2,
                                     '无法获取下一次赎回集中确认日',
                                     self.invest_id,
                                     O_FLAG,
                                     O_MSG);
      RETURN;
    end if;
  
    self.PROC_EX_INIT_CO_OPDATE_REL(V_RED_INVEST_TIME);
  
    self.PROC_DEAL_POP_TO_TERM(V_RED_INVEST_TIME);
  
    IF self.FUNC_EXIST_QUOTIENT_REMAIN THEN
      self.PROC_SET_O_FLAG_AND_O_MSG(2,
                                     '进行后进先出处理时，资产不足',
                                     self.invest_id,
                                     O_FLAG,
                                     O_MSG);
      return;
    END IF;
    self.PROC_DEAL_POP_TO_APPL;
  
    IF self.FUNC_IS_RED_TOTAL_AMT_NOTEQ THEN
      self.PROC_SET_O_FLAG_AND_O_MSG(2,
                                     '赎回份额分配出错',
                                     self.invest_id,
                                     O_FLAG,
                                     O_MSG);
      return;
    END IF;
  
    IF self.FUNC_IS_APPL_MORE_THEN_FIVE(V_MSG) THEN
      self.PROC_SET_O_FLAG_AND_O_MSG(3,
                                     V_MSG,
                                     self.invest_id,
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
    --外部包调用子类内部方法，不支持直接放在外部包的方法内，需要分开写。
    v_plan_id demo_plan_info.plan_id%type := self.func_get_plan_id_by_invest_id;
  BEGIN
    --获取最近一次的集中确认日
    SELECT MIN(T.DEMO_INVEST_TIME)
      INTO V_RED_INVEST_TIME
      FROM V_INVEST_OP_CONTROL T
     WHERE T.INVEST_ID = self.invest_id
       AND T.OP_TYPE = RED_OP_TYPE
       AND T.DEMO_INVEST_TIME >
           PKG_DEMO_COMMON.FUNC_GET_PLANTIMEBYID(v_plan_id);
    RETURN V_RED_INVEST_TIME;
  END;

  member PROCEDURE PROC_SET_O_FLAG_AND_O_MSG(V_FLAG   IN NUMBER,
                                             V_MSG    IN VARCHAR2,
                                             V_PARAMS IN VARCHAR2,
                                             O_FLAG   IN OUT NUMBER,
                                             O_MSG    IN OUT VARCHAR2) IS
  
  BEGIN
    O_FLAG := V_FLAG;
    O_MSG  := V_MSG;
    PACK_LOG.LOG(PROC_NAME,
                 NULL,
                 O_MSG || '|' || V_PARAMS,
                 PACK_LOG.WARN_LEVEL);
  
  END;
  member FUNCTION FUNC_IS_RED_TOTAL_AMT_NOTEQ RETURN BOOLEAN IS
    V_RED_TOTAL_AMT    NUMBER(17, 2);
    V_RESULT_TOTAL_AMT NUMBER(17, 2);
  BEGIN
    SELECT NVL(SUM(AMT), 0) INTO V_RED_TOTAL_AMT FROM DEMO_INVEST_POP_TMP;
    SELECT NVL(SUM(quotient), 0)
      INTO V_RESULT_TOTAL_AMT
      FROM DEMO_INVEST_POP_RESULT_TMP;
  
    RETURN V_RED_TOTAL_AMT <> V_RESULT_TOTAL_AMT;
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
