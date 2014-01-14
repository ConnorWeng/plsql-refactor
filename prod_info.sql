drop type prod_info force;
create or replace type prod_info as object
(
  PROC_NAME                     varchar2(200),
  EVAL_STATE_FLAG_RECENT_TRADED number(1),
  invest_id varchar2(6),
  static function create_prod_info(I_INVEST_ID IN VARCHAR2)
    return prod_info,
  static function FUNC_IS_EXPERT_LCR(I_INVEST_ID in varchar2) return boolean,
  member procedure PROC_DEAL_POP(o_flag in out number,
                                 o_msg  in out varchar2),
  member PROCEDURE PROC_SET_O_FLAG_AND_O_MSG(V_FLAG   IN NUMBER,
                                             V_MSG    IN VARCHAR2,
                                             V_PARAMS IN VARCHAR2,
                                             O_FLAG   IN OUT NUMBER,
                                             O_MSG    IN OUT VARCHAR2),
  member FUNCTION FUNC_IS_RED_TOTAL_AMT_NOTEQ RETURN BOOLEAN,
  member procedure PROC_INIT_AND_CLEANUP
)
not final;
/
create or replace type body prod_info is
  static function create_prod_info(I_INVEST_ID IN VARCHAR2)
    return prod_info is
  begin
    IF FUNC_IS_EXPERT_LCR(I_INVEST_ID) THEN
      return ex_prod_info(i_invest_id);
    ELSE
      return unex_prod_info(i_invest_id);
    END IF;
  end;
  static function FUNC_IS_EXPERT_LCR(I_INVEST_ID in varchar2) return boolean is
  BEGIN
    RETURN PKG_DEMO_COMMON.FUNC_IS_EXPERT_LCR(I_INVEST_ID) = 0;
  END;
  member procedure PROC_DEAL_POP(o_flag in out number,
                                 o_msg  in out varchar2) is
  begin
    return;
  end;
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
  
  member procedure PROC_INIT_AND_CLEANUP is
  begin
    UPDATE DEMO_INVEST_POP_TMP SET quotient_remain = AMT;
  
    DELETE FROM DEMO_INVEST_POP_RESULT_TMP;
  end PROC_INIT_AND_CLEANUP;

end;
/
