CREATE OR REPLACE PACKAGE PKG_DEMO_COMMON IS
  FUNCTION FUNC_IS_EXPERT_LCR(p_invest_id VARCHAR2) RETURN NUMBER;
  FUNCTION FUNC_GET_PLANTIMEBYID(ID IN VARCHAR2) RETURN VARCHAR2;
  FUNCTION FUNC_GET_COFNAMEBYID(id IN VARCHAR2) RETURN VARCHAR2;

  ret_of_func_is_expert_lcr number;
end;
/

CREATE OR REPLACE PACKAGE BODY PKG_DEMO_COMMON IS
  FUNCTION FUNC_IS_EXPERT_LCR(p_invest_id VARCHAR2) RETURN NUMBER is
  begin
  	return ret_of_func_is_expert_lcr;
  end;

  FUNCTION FUNC_GET_PLANTIMEBYID(ID IN VARCHAR2) RETURN VARCHAR2 is
  begin
    utassert.eq(msg_in          => 'plan_id is correct',
                check_this_in   => ID,
                against_this_in => UT_PKG_DEMO_COMMON.plan_id);

  	return '2013-12-01';
  end;

  FUNCTION FUNC_GET_COFNAMEBYID(id IN VARCHAR2) RETURN VARCHAR2 is
  begin
  	return id;
  end;

End;
/
