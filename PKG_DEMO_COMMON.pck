CREATE OR REPLACE PACKAGE PKG_DEMO_COMMON IS
  /***********************************************************
    --存储过程名：    FUNC_IS_EXPERT_LCR
    --存储过程描述：  判断是否是预期收益型
    --功能：          判断是否是预期收益型
    --功能模块：      公共模块管理
    --创建人员：      叶丹
    --创建时间：      2011-08-22
    --参数说明：
    --p_invest_id      投资组合编码
    --返回0表示是预期收益型 1表示是净值报价型
  ***********************************************************/
  FUNCTION FUNC_IS_EXPERT_LCR(p_invest_id VARCHAR2) RETURN NUMBER;

    /*********************************************************************
    --名称:FUNC_GET_PLANNAMEBYID
    --描述:根据计划、企业、员工编码获取计划名称
    --功能:根据计划、企业、员工编码获取计划名称
    --模块:公共
    --作者:zhangym
    --时间:2011-10-28
    --参数:
      ID IN VARCHAR2  --计划、企业、员工编码
  *********************************************************************/
  FUNCTION FUNC_GET_PLANNAMEBYID(ID IN VARCHAR2) RETURN VARCHAR2;
  /*********************************************************************
    --名称:FUNC_GET_PLANTIMEBYID
    --描述:根据计划、企业、员工编码获取计划时间
    --功能:根据计划、企业、员工编码获取计划时间
    --模块:公共
    --作者:zhangym
    --时间:2011-10-28
    --参数:
      ID IN VARCHAR2  --计划、企业、员工编码
  *********************************************************************/
  FUNCTION FUNC_GET_PLANTIMEBYID(ID IN VARCHAR2) RETURN VARCHAR2;
    /*********************************************************************/
    --存储过程名称： FUNC_GET_COFNAMEBYID
    --存储过程描述： 根据id获取企业全称
    --功能：         根据id获取企业全称
    --功能模块：
    --作者：         郑明迪
    --时间：         2010-05-15
    /*********************************************************************/
    FUNCTION FUNC_GET_COFNAMEBYID(id IN VARCHAR2) RETURN VARCHAR2;
END PKG_DEMO_COMMON;
/
CREATE OR REPLACE PACKAGE BODY PKG_DEMO_COMMON IS
  /***********************************************************
    --存储过程名：    FUNC_IS_EXPERT_LCR
    --存储过程描述：  判断是否是预期收益型
    --功能：          判断是否是预期收益型
    --功能模块：      公共模块管理
    --创建人员：      叶丹
    --创建时间：      2011-08-22
    --参数说明：
    --p_invest_id      投资组合编码
    --返回0表示是预期收益型 1表示是净值报价型
  ***********************************************************/
  FUNCTION FUNC_IS_EXPERT_LCR(p_invest_id VARCHAR2) RETURN NUMBER IS
    v_count NUMBER;
  BEGIN

    SELECT COUNT(1)
      INTO v_count
      FROM demo_invest_basic_info
     WHERE invest_id = p_invest_id
       AND buy_way = 1;

    IF v_count <> 0 THEN
      RETURN 1;
    ELSE
      RETURN 0;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END FUNC_IS_EXPERT_LCR;

    /*********************************************************************
    --名称:FUNC_GET_PLANNAMEBYID
    --描述:根据计划、企业、员工编码获取计划名称
    --功能:根据计划、企业、员工编码获取计划名称
    --模块:公共
    --作者:zhangym
    --时间:2011-10-28
    --参数:
      ID IN VARCHAR2  --计划、企业、员工编码
  *********************************************************************/
  FUNCTION FUNC_GET_PLANNAMEBYID(ID IN VARCHAR2) RETURN VARCHAR2 IS
    V_PLAN_NAME DEMO_PLAN_INFO.PLAN_NAME%TYPE := NULL;
    V_LENGTH    NUMBER := LENGTH(ID);
  BEGIN
    IF V_LENGTH = 6 THEN
      SELECT T.PLAN_NAME
        INTO V_PLAN_NAME
        FROM DEMO_PLAN_INFO T
       WHERE T.PLAN_ID = ID;
    ELSIF V_LENGTH = 13 THEN
      SELECT T2.PLAN_NAME
        INTO V_PLAN_NAME
        FROM DEMO_CO_INFO T1, DEMO_PLAN_INFO T2
       WHERE T1.CO_ID = ID
         AND T2.PLAN_ID = T1.PLAN_ID;
    ELSIF V_LENGTH = 10 THEN
      SELECT T3.PLAN_NAME
        INTO V_PLAN_NAME
        FROM DEMO_EMP_INFO T1, DEMO_CO_INFO T2, DEMO_PLAN_INFO T3
       WHERE T1.EMP_ID = ID
         AND T2.CO_ID = T1.CO_ID
         AND T3.PLAN_ID = T2.PLAN_ID;
    END IF;
    RETURN V_PLAN_NAME;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END FUNC_GET_PLANNAMEBYID;
  /*********************************************************************
    --名称:FUNC_GET_PLANTIMEBYID
    --描述:根据计划、企业、员工编码获取计划时间
    --功能:根据计划、企业、员工编码获取计划时间
    --模块:公共
    --作者:zhangym
    --时间:2011-10-28
    --参数:
      ID IN VARCHAR2  --计划、企业、员工编码
  *********************************************************************/
  FUNCTION FUNC_GET_PLANTIMEBYID(ID IN VARCHAR2) RETURN VARCHAR2 IS
    V_PLAN_TIME DEMO_PLAN_INFO.PLAN_TIME%TYPE := NULL;
    V_LENGTH    NUMBER := LENGTH(ID);
  BEGIN
    IF V_LENGTH = 6 THEN
      SELECT T.PLAN_TIME
        INTO V_PLAN_TIME
        FROM DEMO_PLAN_INFO T
       WHERE T.PLAN_ID = ID;
    ELSIF V_LENGTH = 13 THEN
      SELECT T2.PLAN_TIME
        INTO V_PLAN_TIME
        FROM DEMO_CO_INFO T1, DEMO_PLAN_INFO T2
       WHERE T1.CO_ID = ID
         AND T2.PLAN_ID = T1.PLAN_ID;
    ELSIF V_LENGTH = 10 THEN
      SELECT T3.PLAN_TIME
        INTO V_PLAN_TIME
        FROM DEMO_EMP_INFO T1, DEMO_CO_INFO T2, DEMO_PLAN_INFO T3
       WHERE T1.EMP_ID = ID
         AND T2.CO_ID = T1.CO_ID
         AND T3.PLAN_ID = T2.PLAN_ID;
    END IF;
    RETURN V_PLAN_TIME;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN '';
  END FUNC_GET_PLANTIMEBYID;
    /*********************************************************************/
    --存储过程名称： FUNC_GET_COFNAMEBYID
    --存储过程描述： 根据id获取企业全称
    --功能：         根据id获取企业全称
    --功能模块：
    --作者：         郑明迪
    --时间：         2010-05-15
    /*********************************************************************/
    FUNCTION FUNC_GET_COFNAMEBYID(id IN VARCHAR2) RETURN VARCHAR2
    IS
      v_co_fname                  DEMO_CO_INFO.CO_FNAME%TYPE:=null;
    BEGIN
      IF id = '0000000000000' THEN
        RETURN id;
      END IF;
      SELECT T.CO_FNAME
        INTO v_co_fname
        FROM demo_co_info T
       WHERE T.CO_ID = id;
      RETURN v_co_fname;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN id;
    END FUNC_GET_COFNAMEBYID;
END PKG_DEMO_COMMON;
/
