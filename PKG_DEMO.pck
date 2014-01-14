CREATE OR REPLACE PACKAGE PKG_DEMO IS

  PROC_NAME                     CONSTANT DB_LOG.PROC_NAME%TYPE := 'PKG_DEMO.PROC_DEAL_POP';
  EVAL_STATE_FLAG_RECENT_TRADED constant demo_invest_unit_value.EVAL_STATE_FLAG%type := 2;

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
END PKG_DEMO;
/
CREATE OR REPLACE PACKAGE BODY PKG_DEMO IS
  procedure PROC_INIT_AND_CLEANUP is
  begin
    --剩余调整额字段初始化
    UPDATE DEMO_INVEST_POP_TMP SET quotient_remain = AMT;
  
    DELETE FROM DEMO_INVEST_POP_RESULT_TMP;
  end PROC_INIT_AND_CLEANUP;
  

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
    v_prod_info prod_info;
  BEGIN
    O_FLAG := 0;
    O_MSG  := '成功';
  
    PROC_INIT_AND_CLEANUP;
    v_prod_info := prod_info.create_prod_info(i_invest_id);
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



END PKG_DEMO;
/
