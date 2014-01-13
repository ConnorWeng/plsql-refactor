CREATE OR REPLACE PACKAGE PKG_DEMO IS

  PROC_NAME CONSTANT DB_LOG.PROC_NAME%TYPE := 'PKG_DEMO.PROC_DEAL_POP';

  -- Author  : KFZX-WANGYANG01
  -- Created : 2011-9-8 18:00:15
  -- Purpose :
  /*********************************************************************
  --存储过程名称： PROC_DEAL_POP
  --存储过程描述： 资产后进先出拆分处理
  --功能：         在DEMO_INVEST_POP_TMP中存入需要进行后进先出的业务对象和需要提取的总金额
                   程序在DEMO_INVEST_POP_RESULT_TMP中返回后进先出的结果
  --功能模块：     通用
  --作者：
  --时间：
  --I_INVEST_ID IN VARCHAR2,  投资组合代码
    O_FLAG      OUT NUMBER,   错误代码
    O_MSG       OUT VARCHAR2  错误信息
  *********************************************************************/
  PROCEDURE PROC_DEAL_POP(I_INVEST_ID IN VARCHAR2,
                          O_FLAG      OUT NUMBER,
                          O_MSG       OUT VARCHAR2);
  /*********************************************************************
    --名称:FUNC_GET_RED_ABLE
    --描述:判断是否可赎回
    --功能:判断是否可赎回
    --模块:交易管理-集中确认
    --作者:
    --时间:
    --参数:
      I_INVEST_ID           IN VARCHAR2, --投资组合
      I_RED_INVEST_TIME     IN VARCHAR2, --本次赎回集中确认日
      I_BUY_INVEST_TIME     IN VARCHAR2  --购买集中确认日
    --返回：0，可以赎回；1，不能赎回
  *********************************************************************/
  FUNCTION FUNC_GET_RED_ABLE(I_INVEST_ID       IN VARCHAR2,
                             I_RED_INVEST_TIME IN VARCHAR2,
                             I_BUY_INVEST_TIME IN VARCHAR2) RETURN NUMBER;
  /*********************************************************************/
  --存储过程名称： FUNC_GET_FULL_LCR_DATE
  --存储过程描述： 根据根据赎回日期，获取对应的期满赎回日期
  --功能：         根据根据赎回日期，获取对应的期满赎回日期
  --功能模块：
  --作者：
  --时间：
  /*********************************************************************/
  FUNCTION FUNC_GET_FULL_LCR_DATE(I_INVEST_ID IN VARCHAR2,
                                  I_RED_DATE  IN VARCHAR2) RETURN VARCHAR2;
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
  FUNCTION FUNC_GET_RED_PRIORITY(p_invest_id       IN VARCHAR2,
                                 p_invest_time     IN VARCHAR2,
                                 p_invest_red_time IN VARCHAR2)
    RETURN VARCHAR2;
  function FUNC_GET_PLAN_ID_BY_INVEST_ID(i_invest_id in varchar2) return varchar2;
  PROCEDURE PROC_DEAL_POP_EX(i_invest_id in varchar2,
                             o_flag      in out number,
                             o_msg       in out varchar2);
  PROCEDURE PROC_DEAL_POP_UNEX(i_invest_id in varchar2,
                               o_flag      in out number,
                               o_msg       in out varchar2);
END PKG_DEMO;
/
CREATE OR REPLACE PACKAGE BODY PKG_DEMO IS
    procedure PROC_INIT_AND_CLEANUP is
  begin
    --剩余调整额字段初始化
    UPDATE DEMO_INVEST_POP_TMP SET AMT_REMAIN = AMT;
  
    DELETE FROM DEMO_INVEST_POP_RESULT_TMP;
  end PROC_INIT_AND_CLEANUP;

  FUNCTION FUNC_IS_RED_TOTAL_AMT_NOTEQ RETURN BOOLEAN IS
    V_RED_TOTAL_AMT    NUMBER(17, 2);
    V_RESULT_TOTAL_AMT NUMBER(17, 2);
  BEGIN
    SELECT NVL(SUM(AMT), 0) INTO V_RED_TOTAL_AMT FROM DEMO_INVEST_POP_TMP;
    SELECT NVL(SUM(quotient), 0)
      INTO V_RESULT_TOTAL_AMT
      FROM DEMO_INVEST_POP_RESULT_TMP;
  
    RETURN V_RED_TOTAL_AMT <> V_RESULT_TOTAL_AMT;
  END;

  FUNCTION FUNC_IS_APPL_MORE_THEN_FIVE(V_MSG OUT VARCHAR2) RETURN BOOLEAN IS
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
  function FUNC_IS_EXPERT_LCR(I_INVEST_ID in varchar2) return boolean is
  BEGIN
    RETURN PKG_DEMO_COMMON.FUNC_IS_EXPERT_LCR(I_INVEST_ID) = 0;
  END;
  FUNCTION FUNC_NOT_EXIST_DONE_OP_DATE(I_INVEST_ID IN VARCHAR2) RETURN BOOLEAN IS
    eval_state_flag_recent_traded     constant demo_invest_unit_value.EVAL_STATE_FLAG%type := 2;
    V_COUNT NUMBER;
  BEGIN
    SELECT COUNT(1)
      INTO V_COUNT
      FROM DEMO_INVEST_UNIT_VALUE T
     WHERE T.INVEST_ID = I_INVEST_ID
       AND T.EVAL_STATE_FLAG = eval_state_flag_recent_traded;
    RETURN V_COUNT = 0;
  END;
  function FUNC_GET_PLAN_ID_BY_INVEST_ID(i_invest_id in varchar2) return varchar2 is
    V_PLAN_ID DEMO_INVEST_INFO.Plan_Id%type;
  begin
    --获取计划编码
    SELECT PLAN_ID
      INTO V_PLAN_ID
      FROM DEMO_INVEST_INFO
     WHERE INVEST_ID = I_INVEST_ID;
    return V_PLAN_ID;
  end;
  function FUNC_GET_NEXT_RED_TIME(I_INVEST_ID IN VARCHAR2) RETURN VARCHAR2 IS
    RED_OP_TYPE CONSTANT NUMBER := 3;
    V_RED_INVEST_TIME DEMO_INVEST_OP_CONTROL.INVEST_TIME%TYPE;
  BEGIN
    --获取最近一次的集中确认日
    SELECT MIN(T.DEMO_INVEST_TIME)
      INTO V_RED_INVEST_TIME
      FROM V_INVEST_OP_CONTROL T
     WHERE T.INVEST_ID = I_INVEST_ID
       AND T.OP_TYPE = RED_OP_TYPE
       AND T.DEMO_INVEST_TIME >
           PKG_DEMO_COMMON.FUNC_GET_PLANTIMEBYID(func_get_plan_id_by_invest_id(i_invest_id));
    RETURN V_RED_INVEST_TIME;
  END;
    
  PROCEDURE PROC_SET_O_FLAG_AND_O_MSG(V_FLAG   IN NUMBER,
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
  

  
  /*********************************************************************
  --存储过程名称： PROC_DEAL_POP
  --存储过程描述： 资产后进先出拆分处理
  --功能：         在DEMO_INVEST_POP_TMP中存入需要进行后进先出的业务对象和需要提取的总金额
                   程序在DEMO_INVEST_POP_RESULT_TMP中返回后进先出的结果
  --功能模块：     通用
  --作者：
  --时间：
  --I_INVEST_ID IN VARCHAR2,  投资组合代码
    O_FLAG      OUT NUMBER,   错误代码
    O_MSG       OUT VARCHAR2  错误信息
  *********************************************************************/
  PROCEDURE PROC_DEAL_POP(I_INVEST_ID IN VARCHAR2,
                          O_FLAG      OUT NUMBER,
                          O_MSG       OUT VARCHAR2) IS
  BEGIN
    O_FLAG := 0;
    O_MSG  := '成功';
  
    PROC_INIT_AND_CLEANUP;
  
    IF FUNC_IS_EXPERT_LCR(I_INVEST_ID) THEN
      PROC_DEAL_POP_EX(i_invest_id, o_flag, O_MSG);
    ELSE
      PROC_DEAL_POP_UNEX(i_invest_id, o_flag, O_MSG);
    END IF;
  
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
  FUNCTION FUNC_GET_RED_ABLE(I_INVEST_ID       IN VARCHAR2,
                             I_RED_INVEST_TIME IN VARCHAR2,
                             I_BUY_INVEST_TIME IN VARCHAR2) RETURN NUMBER IS
    V_ISSUE_WAY      DEMO_INVEST_BASIC_INFO.ISSUE_WAY%TYPE;
    v_SELL_MIN_TERM  DEMO_INVEST_BASIC_INFO.Sell_Min_Term%TYPE;
    v_OPEN_SELL_TERM DEMO_INVEST_BASIC_INFO.OPEN_SELL_TERM%TYPE;
    v_max_TERM_NO    DEMO_INVEST_OP_CONTROL.term_no%TYPE;
    v_min_TERM_NO    DEMO_INVEST_OP_CONTROL.term_no%TYPE;
  
  BEGIN
    SELECT ISSUE_WAY, SELL_MIN_TERM, OPEN_SELL_TERM
      INTO V_ISSUE_WAY, v_SELL_MIN_TERM, v_OPEN_SELL_TERM
      FROM DEMO_INVEST_BASIC_INFO T
     WHERE T.INVEST_ID = I_INVEST_ID;
  
    IF V_ISSUE_WAY = 4 THEN
      --结转型
      SELECT max(TERM_NO)
        INTO v_max_TERM_NO
        FROM v_invest_op_control t
       WHERE t.invest_id = I_INVEST_ID
         and t.op_type in (1, 2)
         AND DEMO_INVEST_TIME = I_RED_INVEST_TIME;
    
      SELECT MAX(TERM_NO)
        INTO v_min_TERM_NO
        FROM v_invest_op_control t
       WHERE t.invest_id = I_INVEST_ID
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
  FUNCTION FUNC_GET_FULL_LCR_DATE(I_INVEST_ID IN VARCHAR2,
                                  I_RED_DATE  IN VARCHAR2) RETURN VARCHAR2 IS
    V_FULL_LCR_DATE VARCHAR2(10);
  BEGIN
    SELECT MAX(T.demo_invest_time)
      INTO V_FULL_LCR_DATE
      FROM V_INVEST_OP_CONTROL T
     WHERE T.INVEST_ID = I_INVEST_ID
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
  FUNCTION FUNC_GET_RED_PRIORITY(p_invest_id       IN VARCHAR2,
                                 p_invest_time     IN VARCHAR2,
                                 p_invest_red_time IN VARCHAR2)
    RETURN VARCHAR2 IS
    v_full_lcr_date DEMO_INVEST_OP_CONTROL.invest_time%TYPE;
  BEGIN
    v_full_lcr_date := PKG_DEMO.FUNC_GET_FULL_LCR_DATE(p_invest_id,
                                                       p_invest_red_time);
    IF v_full_lcr_date = p_invest_time THEN
      --这一期恰好期满，赎回采用高优先级
      RETURN '9999-12-31';
    END IF;
    RETURN p_invest_time;
  
  EXCEPTION
    WHEN OTHERS THEN
      RETURN p_invest_time;
  END FUNC_GET_RED_PRIORITY;
  
  procedure PROC_EX_INIT_CO_OPDATE_REL(I_INVEST_ID IN VARCHAR2,
                                       I_RED_INVEST_TIME IN VARCHAR2) IS
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
         AND T1.INVEST_ID = I_INVEST_ID
         AND PKG_DEMO.FUNC_GET_RED_ABLE(I_INVEST_ID,
                                        I_RED_INVEST_TIME,
                                        T1.INVEST_TIME) = 0 --满足最低赎回期数
      UNION
      SELECT T1.INVEST_TIME, T1.CO_ID
        FROM DEMO_CO_INVEST_TERM T1
       WHERE (T1.CO_ID, T1.SUBJECT_TYPE) IN
             (SELECT CO_ID, SUBJECT_TYPE
                FROM DEMO_INVEST_POP_TMP
               WHERE SUBJECT_TYPE NOT LIKE '301%')
         AND T1.AMT > 0
         AND T1.INVEST_ID = I_INVEST_ID
         AND PKG_DEMO.FUNC_GET_RED_ABLE(I_INVEST_ID,
                                        I_RED_INVEST_TIME,
                                        T1.INVEST_TIME) = 0;
  end;
  
  PROCEDURE PROC_DEAL_POP_EX_EMP(I_INVEST_ID   IN VARCHAR2,
                                 I_INVEST_TIME IN VARCHAR2) IS
  
  BEGIN
    INSERT INTO DEMO_INVEST_POP_RESULT_TMP
      (EMP_ID, CO_ID, SUBJECT_TYPE, INVEST_TIME, AMT, QUOTIENT)
      SELECT T1.EMP_ID,
             T1.CO_ID,
             T1.SUBJECT_TYPE,
             T2.INVEST_TIME,
             LEAST(T1.AMT_REMAIN, T2.AMT), --min(赎回申请金额，余额 - 待赎回金额)
             LEAST(T1.AMT_REMAIN, T2.AMT)
        FROM DEMO_INVEST_POP_TMP T1, DEMO_EMP_INVEST_TERM T2
       WHERE T1.EMP_ID = T2.EMP_ID
         AND T1.SUBJECT_TYPE = T2.SUBJECT_TYPE
         AND T2.INVEST_ID = I_INVEST_ID
         AND T2.INVEST_TIME = I_INVEST_TIME
         AND T2.AMT > 0
         AND T1.AMT_REMAIN > 0
         AND T1.EMP_ID <> 'FFFFFFFFFF';
  
  END;
  PROCEDURE PROC_DEAL_POP_EX_CO(I_INVEST_ID   IN VARCHAR2,
                                 I_INVEST_TIME IN VARCHAR2) IS
  BEGIN
    --企业部分
      INSERT INTO DEMO_INVEST_POP_RESULT_TMP
        (EMP_ID, CO_ID, SUBJECT_TYPE, INVEST_TIME, AMT, QUOTIENT)
        SELECT T1.EMP_ID,
               T1.CO_ID,
               T1.SUBJECT_TYPE,
               T2.INVEST_TIME,
               LEAST(T1.AMT_REMAIN, T2.AMT),
               LEAST(T1.AMT_REMAIN, T2.AMT)
          FROM DEMO_INVEST_POP_TMP T1, DEMO_CO_INVEST_TERM T2
         WHERE T1.CO_ID = T2.CO_ID
           AND T1.SUBJECT_TYPE = T2.SUBJECT_TYPE
           AND T2.INVEST_ID = I_INVEST_ID
           AND T2.INVEST_TIME = I_INVEST_TIME
           AND T2.AMT > 0
           AND T1.AMT_REMAIN > 0
           AND T1.EMP_ID = 'FFFFFFFFFF';
  END;
  
  FUNCTION FUNC_IS_TOTAL_TO_TERM_DONE(I_INVEST_TIME IN VARCHAR2) RETURN BOOLEAN IS
    V_COUNT NUMBER;
  BEGIN
    MERGE INTO DEMO_INVEST_POP_TMP A
      USING DEMO_INVEST_POP_RESULT_TMP B
      ON (A.EMP_ID = B.EMP_ID AND A.SUBJECT_TYPE = B.SUBJECT_TYPE AND A.CO_ID = B.CO_ID AND B.INVEST_TIME = I_INVEST_TIME)
      WHEN MATCHED THEN
        UPDATE SET A.AMT_REMAIN = A.AMT_REMAIN - B.quotient;
    
      SELECT COUNT(1)
        INTO V_COUNT
        FROM DEMO_INVEST_POP_TMP
       WHERE AMT_REMAIN > 0
         AND ROWNUM = 1;
      
      RETURN V_COUNT = 0;
  END;
    
  

  PROCEDURE PROC_DEAL_POP_EX(i_invest_id in varchar2,
                             o_flag      in out number,
                             o_msg       in out varchar2) is
    V_PARAMS    VARCHAR2(4000) := I_INVEST_ID;
    V_STEP      NUMBER := NULL;
    --V_FLAG      NUMBER := NULL;
    V_MSG VARCHAR2(4000) := NULL;
    E_CUSTOM EXCEPTION;
    E_APP_COUNT EXCEPTION;
  
    V_COUNT           NUMBER;
    V_RED_INVEST_TIME DEMO_INVEST_OP_CONTROL.INVEST_TIME%TYPE := NULL;
    V_AMT             NUMBER(17, 2) := NULL;
    V_AMT2            NUMBER(17, 2) := NULL;
  begin
    --获取最近一次的集中确认日
    V_RED_INVEST_TIME := FUNC_GET_NEXT_RED_TIME(I_INVEST_ID);
    
  
    if V_RED_INVEST_TIME is null then
      PROC_SET_O_FLAG_AND_O_MSG(2,'无法获取下一次赎回集中确认日',I_INVEST_ID,O_FLAG,O_MSG);
      RETURN;
    end if;
    
    PROC_EX_INIT_CO_OPDATE_REL(I_INVEST_ID,V_RED_INVEST_TIME);
  
    FOR RS IN (SELECT T1.OP_DATE INVEST_TIME
                 FROM DEMO_OP_CO T1
                ORDER BY pkg_demo.FUNC_GET_RED_PRIORITY(I_INVEST_ID,
                                                         T1.OP_DATE,
                                                        V_RED_INVEST_TIME) DESC) LOOP
                                                        
      PROC_DEAL_POP_EX_EMP(I_INVEST_ID,RS.INVEST_TIME);
      PROC_DEAL_POP_EX_CO(I_INVEST_ID,RS.INVEST_TIME);
    
      EXIT WHEN FUNC_IS_TOTAL_TO_TERM_DONE(RS.INVEST_TIME);
    END LOOP;
  
    SELECT COUNT(1)
      INTO V_COUNT
      FROM DEMO_INVEST_POP_TMP
     WHERE AMT_REMAIN > 0
       AND ROWNUM = 1;
    IF V_COUNT > 0 THEN
      V_MSG := '进行后进先出处理时，资产不足';
      RAISE E_CUSTOM;
    END IF;
  
    FOR RS IN (SELECT *
                 FROM DEMO_INVEST_POP_RESULT_TMP T1
                WHERE T1.YAPPL_NUM IS NULL) LOOP
    
      V_AMT := RS.AMT;
    
      FOR RS1 IN (SELECT *
                    FROM DEMO_APPL_NUM_REL T2
                   WHERE T2.CO_ID = RS.CO_ID
                     AND T2.INVEST_ID = I_INVEST_ID
                     AND T2.INVEST_TIME = RS.INVEST_TIME
                     AND T2.AMT > 0
                     AND T2.AMT - NVL(T2.RED_AMT, 0) > 0) LOOP
        --对于一期有多张申请单的情况进行倒序获取
      
        IF V_AMT > 0 THEN
          SELECT RS1.AMT - NVL(RS1.RED_AMT, 0) - NVL(SUM(T3.AMT), 0)
            INTO V_AMT2
            FROM DEMO_INVEST_POP_RESULT_TMP T3
           WHERE T3.CO_ID = RS1.CO_ID
             AND T3.INVEST_TIME = RS1.INVEST_TIME
             AND T3.YAPPL_NUM = RS1.APPL_NUM;
        
          IF V_AMT2 > 0 THEN
            INSERT INTO DEMO_INVEST_POP_RESULT_TMP
              (EMP_ID,
               CO_ID,
               SUBJECT_TYPE,
               INVEST_TIME,
               AMT,
               QUOTIENT,
               YAPPL_NUM)
            VALUES
              (RS.EMP_ID,
               RS.CO_ID,
               RS.SUBJECT_TYPE,
               RS.INVEST_TIME,
               LEAST(V_AMT, V_AMT2),
               LEAST(V_AMT, V_AMT2),
               RS1.APPL_NUM);
          
            V_AMT := V_AMT - LEAST(V_AMT, V_AMT2);
          END IF;
        END IF;
      END LOOP;
    END LOOP;
    DELETE FROM DEMO_INVEST_POP_RESULT_TMP WHERE YAPPL_NUM IS NULL;
  
    IF FUNC_IS_RED_TOTAL_AMT_NOTEQ THEN
      V_MSG := '赎回份额分配出错';
      RAISE E_CUSTOM;
    END IF;
  
    IF FUNC_IS_APPL_MORE_THEN_FIVE(V_MSG) THEN
      RAISE E_APP_COUNT;
    END IF;
  
  EXCEPTION
    WHEN E_CUSTOM THEN
      --ROLLBACK;
      O_FLAG := 2;
      O_MSG  := V_MSG;
      PACK_LOG.LOG(PROC_NAME,
                   V_STEP,
                   O_MSG || '|' || V_PARAMS,
                   PACK_LOG.WARN_LEVEL);
    WHEN E_APP_COUNT THEN
      --ROLLBACK;
      O_FLAG := 3;
      O_MSG  := V_MSG;
      PACK_LOG.LOG(PROC_NAME,
                   V_STEP,
                   O_MSG || '|' || V_PARAMS,
                   PACK_LOG.WARN_LEVEL);
  end;
  
    PROCEDURE PROC_DEAL_POP_UNEX_EMP(I_INVEST_ID IN VARCHAR2) IS
  BEGIN
    INSERT INTO DEMO_INVEST_POP_RESULT_TMP
      (EMP_ID, CO_ID, SUBJECT_TYPE, INVEST_TIME, AMT, QUOTIENT, YAPPL_NUM)
      SELECT T1.EMP_ID,
             T1.CO_ID,
             T1.SUBJECT_TYPE,
             (SELECT T3.EVALUATE_DATE
                FROM DEMO_INVEST_UNIT_VALUE T3
               WHERE T3.INVEST_ID = T2.INVEST_ID
                 AND T3.EVAL_STATE_FLAG = 2),
             LEAST(T1.AMT_REMAIN, T2.quotient) / t2.quotient * t2.amt,
             LEAST(T1.AMT_REMAIN, T2.quotient),
             0
        FROM DEMO_INVEST_POP_TMP T1, DEMO_EMP_INVEST T2
       WHERE T1.EMP_ID = T2.EMP_ID
         AND T1.SUBJECT_TYPE = T2.SUBJECT_TYPE
         AND T2.INVEST_ID = I_INVEST_ID
         AND T2.quotient > 0
         AND T1.AMT_REMAIN > 0
         AND T1.EMP_ID <> 'FFFFFFFFFF';
  END;
  
  PROCEDURE PROC_DEAL_POP_UNEX_CO(I_INVEST_ID IN VARCHAR2) IS
    
  BEGIN
    INSERT INTO DEMO_INVEST_POP_RESULT_TMP
      (EMP_ID, CO_ID, SUBJECT_TYPE, INVEST_TIME, AMT, QUOTIENT, YAPPL_NUM)
      SELECT T1.EMP_ID,
             T1.CO_ID,
             T1.SUBJECT_TYPE,
             (SELECT T3.EVALUATE_DATE
                FROM DEMO_INVEST_UNIT_VALUE T3
               WHERE T3.INVEST_ID = T2.INVEST_ID
                 AND T3.EVAL_STATE_FLAG = 2),
             LEAST(T1.AMT_REMAIN, T2.quotient) / t2.quotient * t2.amt,
             LEAST(T1.AMT_REMAIN, T2.quotient),
             0
        FROM DEMO_INVEST_POP_TMP T1, DEMO_CO_INVEST T2
       WHERE T1.CO_ID = T2.CO_ID
         AND T1.SUBJECT_TYPE = T2.SUBJECT_TYPE
         AND T2.INVEST_ID = I_INVEST_ID
         AND T2.quotient > 0
         AND T1.AMT_REMAIN > 0
         AND T1.EMP_ID = 'FFFFFFFFFF';
    
  END;

  PROCEDURE PROC_DEAL_POP_UNEX(i_invest_id in varchar2,
                               o_flag      in out number,
                               o_msg       in out varchar2) is
  begin
    IF FUNC_NOT_EXIST_DONE_OP_DATE(I_INVEST_ID) THEN
      PROC_SET_O_FLAG_AND_O_MSG(2,'系统中不存在已完成的集中确认日，无法进行后续操作！',I_INVEST_ID,O_FLAG,O_MSG);
      RETURN;
    END IF;
    
    PROC_DEAL_POP_UNEX_EMP(I_INVEST_ID);
    PROC_DEAL_POP_UNEX_CO(I_INVEST_ID);
  
    IF FUNC_IS_RED_TOTAL_AMT_NOTEQ THEN
      PROC_SET_O_FLAG_AND_O_MSG(2,'赎回份额分配出错！',I_INVEST_ID,O_FLAG,O_MSG);
      RETURN;
    END IF;
  end;

END PKG_DEMO;
/
