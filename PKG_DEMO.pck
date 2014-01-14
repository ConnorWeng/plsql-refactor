CREATE OR REPLACE PACKAGE PKG_DEMO IS

  PROC_NAME                     CONSTANT DB_LOG.PROC_NAME%TYPE := 'PKG_DEMO.PROC_DEAL_POP';
  EVAL_STATE_FLAG_RECENT_TRADED constant demo_invest_unit_value.EVAL_STATE_FLAG%type := 2;

  -- Author  : KFZX-WANGYANG01
  -- Created : 2011-9-8 18:00:15
  -- Purpose :
  /*********************************************************************
  --�洢�������ƣ� PROC_DEAL_POP
  --�洢���������� �ʲ�����ȳ���ִ���
  --���ܣ�         ��DEMO_INVEST_POP_TMP�д�����Ҫ���к���ȳ���ҵ��������Ҫ��ȡ���ܽ��
                   ������DEMO_INVEST_POP_RESULT_TMP�з��غ���ȳ��Ľ��
  --����ģ�飺     ͨ��
  --���ߣ�
  --ʱ�䣺
  --I_INVEST_ID IN VARCHAR2,  Ͷ����ϴ���
    O_FLAG      OUT NUMBER,   �������
    O_MSG       OUT VARCHAR2  ������Ϣ
  *********************************************************************/
  PROCEDURE PROC_DEAL_POP(I_INVEST_ID IN VARCHAR2,
                          O_FLAG      OUT NUMBER,
                          O_MSG       OUT VARCHAR2);
  /*********************************************************************
    --����:FUNC_GET_RED_ABLE
    --����:�ж��Ƿ�����
    --����:�ж��Ƿ�����
    --ģ��:���׹���-����ȷ��
    --����:
    --ʱ��:
    --����:
      I_INVEST_ID           IN VARCHAR2, --Ͷ�����
      I_RED_INVEST_TIME     IN VARCHAR2, --������ؼ���ȷ����
      I_BUY_INVEST_TIME     IN VARCHAR2  --������ȷ����
    --���أ�0��������أ�1���������
  *********************************************************************/
  FUNCTION FUNC_GET_RED_ABLE(I_INVEST_ID       IN VARCHAR2,
                             I_RED_INVEST_TIME IN VARCHAR2,
                             I_BUY_INVEST_TIME IN VARCHAR2) RETURN NUMBER;
  /*********************************************************************/
  --�洢�������ƣ� FUNC_GET_FULL_LCR_DATE
  --�洢���������� ���ݸ���������ڣ���ȡ��Ӧ�������������
  --���ܣ�         ���ݸ���������ڣ���ȡ��Ӧ�������������
  --����ģ�飺
  --���ߣ�
  --ʱ�䣺
  /*********************************************************************/
  FUNCTION FUNC_GET_FULL_LCR_DATE(I_INVEST_ID IN VARCHAR2,
                                  I_RED_DATE  IN VARCHAR2) RETURN VARCHAR2;
  /*********************************************************************
  --�洢�������ƣ� PROC_GET_RED_PRIORITY
  --�洢���������� ��ȡ������������������ȼ�
  --����ģ�飺     �����������
  --���ߣ�
  --ʱ�䣺
  --����˵����
  --p_invest_id             IN  VARCHAR2,     --Ͷ����ϱ���
  --p_invest_time           IN  VARCHAR2,     --�ʲ����ڵ�����
  --p_invest_red_time       IN  VARCHAR2,     --�ʲ���صļ���ȷ����
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
    --ʣ��������ֶγ�ʼ��
    UPDATE DEMO_INVEST_POP_TMP SET quotient_remain = AMT;
  
    DELETE FROM DEMO_INVEST_POP_RESULT_TMP;
  end PROC_INIT_AND_CLEANUP;
  

  /*********************************************************************
  --�洢�������ƣ� PROC_DEAL_POP
  --�洢���������� �ʲ�����ȳ���ִ���
  --���ܣ�         ��DEMO_INVEST_POP_TMP�д�����Ҫ���к���ȳ���ҵ��������Ҫ��ȡ���ܽ��
                   ������DEMO_INVEST_POP_RESULT_TMP�з��غ���ȳ��Ľ��
  --����ģ�飺     ͨ��
  --���ߣ�
  --ʱ�䣺
  --I_INVEST_ID IN VARCHAR2,  Ͷ����ϴ���
    O_FLAG      OUT NUMBER,   �������
    O_MSG       OUT VARCHAR2  ������Ϣ
  *********************************************************************/
  PROCEDURE PROC_DEAL_POP(I_INVEST_ID IN VARCHAR2,
                          O_FLAG      OUT NUMBER,
                          O_MSG       OUT VARCHAR2) IS
    v_prod_info prod_info;
  BEGIN
    O_FLAG := 0;
    O_MSG  := '�ɹ�';
  
    PROC_INIT_AND_CLEANUP;
    v_prod_info := prod_info.create_prod_info(i_invest_id);
    v_prod_info.PROC_DEAL_POP(O_FLAG,O_MSG);
  
  EXCEPTION
    WHEN OTHERS THEN
      O_FLAG := 1;
      O_MSG  := '���к���ȳ�����ʱ�쳣��';
    
      PACK_LOG.LOG(PROC_NAME,
                   null,
                   O_MSG || '|' || I_INVEST_ID || '|' || SQLERRM || '|' ||
                   DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
                   PACK_LOG.ERR_LEVEL);
  END PROC_DEAL_POP;
  /*********************************************************************
    --����:FUNC_GET_RED_ABLE
    --����:�ж��Ƿ�����
    --����:�ж��Ƿ�����
    --ģ��:���׹���-����ȷ��
    --����:
    --ʱ��:
    --����:
      I_INVEST_ID       IN VARCHAR2,  Ͷ����ϴ���
      I_RED_INVEST_TIME IN VARCHAR2,  ��ؼ���ȷ����
      I_BUY_INVEST_TIME IN VARCHAR2   ������ȷ����
    --���أ�0��������أ�1���������
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
      --��ת��
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
      --����
      RETURN 0;
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 1;
  END FUNC_GET_RED_ABLE;

  /*********************************************************************/
  --�洢�������ƣ� FUNC_GET_FULL_LCR_DATE
  --�洢���������� ���ݸ���������ڣ���ȡ��Ӧ�������������
  --���ܣ�         ���ݸ���������ڣ���ȡ��Ӧ�������������
  --����ģ�飺
  --���ߣ�
  --ʱ�䣺
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
  --�洢�������ƣ� PROC_GET_RED_PRIORITY
  --�洢���������� ��ȡ������������������ȼ�
  --����ģ�飺     �����������
  --���ߣ�
  --ʱ�䣺
  --����˵����
  --p_invest_id             IN  VARCHAR2,     --Ͷ����ϱ���
  --p_invest_time           IN  VARCHAR2,     --�ʲ����ڵ�����
  --p_invest_red_time       IN  VARCHAR2,     --�ʲ���صļ���ȷ����
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
      --��һ��ǡ����������ز��ø����ȼ�
      RETURN '9999-12-31';
    END IF;
    RETURN p_invest_time;
  
  EXCEPTION
    WHEN OTHERS THEN
      RETURN p_invest_time;
  END FUNC_GET_RED_PRIORITY;



END PKG_DEMO;
/
