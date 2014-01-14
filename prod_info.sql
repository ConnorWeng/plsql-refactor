drop type prod_info force;
create or replace type prod_info as object
(
  invest_id varchar2(6),
  constructor function prod_info(I_INVEST_ID IN VARCHAR2)
  return self as result,
  static function create_prod_info(I_INVEST_ID IN VARCHAR2)
    return prod_info,
  static function FUNC_IS_EXPERT_LCR(I_INVEST_ID in varchar2) return boolean,
  member procedure PROC_DEAL_POP(o_flag in out number,
                                 o_msg  in out varchar2)

)
not final;
/
create or replace type body prod_info is
  constructor function prod_info(I_INVEST_ID IN VARCHAR2)
    return self as result is
  begin
    self.invest_id := i_invest_id;
    return;
  end;
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

end;
/
