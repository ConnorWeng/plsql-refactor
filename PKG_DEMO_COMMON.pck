CREATE OR REPLACE PACKAGE PKG_DEMO_COMMON IS
  /***********************************************************
    --�洢��������    FUNC_IS_EXPERT_LCR
    --�洢����������  �ж��Ƿ���Ԥ��������
    --���ܣ�          �ж��Ƿ���Ԥ��������
    --����ģ�飺      ����ģ�����
    --������Ա��      Ҷ��
    --����ʱ�䣺      2011-08-22
    --����˵����
    --p_invest_id      Ͷ����ϱ���
    --����0��ʾ��Ԥ�������� 1��ʾ�Ǿ�ֵ������
  ***********************************************************/
  FUNCTION FUNC_IS_EXPERT_LCR(p_invest_id VARCHAR2) RETURN NUMBER;

    /*********************************************************************
    --����:FUNC_GET_PLANNAMEBYID
    --����:���ݼƻ�����ҵ��Ա�������ȡ�ƻ�����
    --����:���ݼƻ�����ҵ��Ա�������ȡ�ƻ�����
    --ģ��:����
    --����:zhangym
    --ʱ��:2011-10-28
    --����:
      ID IN VARCHAR2  --�ƻ�����ҵ��Ա������
  *********************************************************************/
  FUNCTION FUNC_GET_PLANNAMEBYID(ID IN VARCHAR2) RETURN VARCHAR2;
  /*********************************************************************
    --����:FUNC_GET_PLANTIMEBYID
    --����:���ݼƻ�����ҵ��Ա�������ȡ�ƻ�ʱ��
    --����:���ݼƻ�����ҵ��Ա�������ȡ�ƻ�ʱ��
    --ģ��:����
    --����:zhangym
    --ʱ��:2011-10-28
    --����:
      ID IN VARCHAR2  --�ƻ�����ҵ��Ա������
  *********************************************************************/
  FUNCTION FUNC_GET_PLANTIMEBYID(ID IN VARCHAR2) RETURN VARCHAR2;
    /*********************************************************************/
    --�洢�������ƣ� FUNC_GET_COFNAMEBYID
    --�洢���������� ����id��ȡ��ҵȫ��
    --���ܣ�         ����id��ȡ��ҵȫ��
    --����ģ�飺
    --���ߣ�         ֣����
    --ʱ�䣺         2010-05-15
    /*********************************************************************/
    FUNCTION FUNC_GET_COFNAMEBYID(id IN VARCHAR2) RETURN VARCHAR2;
END PKG_DEMO_COMMON;
/
CREATE OR REPLACE PACKAGE BODY PKG_DEMO_COMMON IS
  /***********************************************************
    --�洢��������    FUNC_IS_EXPERT_LCR
    --�洢����������  �ж��Ƿ���Ԥ��������
    --���ܣ�          �ж��Ƿ���Ԥ��������
    --����ģ�飺      ����ģ�����
    --������Ա��      Ҷ��
    --����ʱ�䣺      2011-08-22
    --����˵����
    --p_invest_id      Ͷ����ϱ���
    --����0��ʾ��Ԥ�������� 1��ʾ�Ǿ�ֵ������
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
    --����:FUNC_GET_PLANNAMEBYID
    --����:���ݼƻ�����ҵ��Ա�������ȡ�ƻ�����
    --����:���ݼƻ�����ҵ��Ա�������ȡ�ƻ�����
    --ģ��:����
    --����:zhangym
    --ʱ��:2011-10-28
    --����:
      ID IN VARCHAR2  --�ƻ�����ҵ��Ա������
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
    --����:FUNC_GET_PLANTIMEBYID
    --����:���ݼƻ�����ҵ��Ա�������ȡ�ƻ�ʱ��
    --����:���ݼƻ�����ҵ��Ա�������ȡ�ƻ�ʱ��
    --ģ��:����
    --����:zhangym
    --ʱ��:2011-10-28
    --����:
      ID IN VARCHAR2  --�ƻ�����ҵ��Ա������
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
    --�洢�������ƣ� FUNC_GET_COFNAMEBYID
    --�洢���������� ����id��ȡ��ҵȫ��
    --���ܣ�         ����id��ȡ��ҵȫ��
    --����ģ�飺
    --���ߣ�         ֣����
    --ʱ�䣺         2010-05-15
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
