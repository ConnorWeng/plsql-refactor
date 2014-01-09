CREATE OR REPLACE PACKAGE UT_PKG_DEMO_PROC_POP_DEAL_UNEX IS
  PROCEDURE UT_SETUP;
  PROCEDURE UT_TEARDOWN;

  PROCEDURE UT_UNEX_EMP_ENOUGH;
  PROCEDURE UT_UNEX_CO_ENOUGH;
  PROCEDURE UT_UNEX_CO_NOTENOUGH;

  procedure create_unex_prod_info;
  procedure create_emp_invest_info(original_amt demo_emp_invest.QUOTIENT%type,
                                   original_quotient demo_emp_invest.AMT%type);
  procedure create_co_invest_info(original_amt demo_emp_invest.QUOTIENT%type,
                                  original_quotient demo_emp_invest.AMT%type);

  procedure assert_quotient_and_amt(expected_red_quotient demo_invest_pop_result_tmp.QUOTIENT%type,
                                    expected_amt demo_invest_pop_result_tmp.AMT%type);
  
  procedure assert_redemption_obj(expected_subject_type in demo_emp_invest.subject_type%type,
                                  expected_emp_id       in demo_emp_invest.emp_id%type);
  procedure assert_detail_by_appl(yappl_num   in number,
                                  expected_invest_time in varchar2,
                                  expected_quotient    in number,
                                  expected_amt         in number);
  procedure assert_result_count(expected_count number);

  True                constant number := 0;
  False               constant number := 1;
  Dummy               constant number := 99;

  invest_id                         constant DEMO_INVEST_INFO.INVEST_ID%type := '990001';
  plan_id                           constant demo_plan_info.plan_id%type := '000001';
  co_id                             constant demo_co_invest.co_id%type := '0000001000000';
  emp_id                            constant demo_emp_invest.emp_id%type := '0000000001';
  emp_id_for_co                     constant demo_emp_invest.emp_id%type := 'FFFFFFFFFF';
  subject_type_emp                  constant demo_emp_invest.subject_type%type := '301001';
  subject_type_co                   constant demo_emp_invest.subject_type%type := '302101';
  op_type_purchase                  constant demo_invest_op_control.OP_TYPE%type := 2;
  op_type_redemption                constant demo_invest_op_control.OP_TYPE%type := 3;
  eval_state_flag_traded            constant demo_invest_unit_value.EVAL_STATE_FLAG%type := 1;
  eval_state_flag_recent_traded     constant demo_invest_unit_value.EVAL_STATE_FLAG%type := 2;
  eval_state_flag_not_excuted       constant demo_invest_unit_value.EVAL_STATE_FLAG%type := 3;
  
  term_one_invest_time              constant VARCHAR2(10) := UT_PKG_DEMO_COMMON.term_one_invest_time;
  term_two_invest_time              constant VARCHAR2(10) := '2013-02-01';
  red_term_invest_time              constant VARCHAR2(10) := UT_PKG_DEMO_COMMON.red_term_invest_time;

  appl_num_one                      constant demo_appl_num_rel.appl_num%type := 1;
  appl_num_two                      constant demo_appl_num_rel.appl_num%type := 2;
  appl_num_three                    constant demo_appl_num_rel.appl_num%type := 3;
  appl_num_four                     constant demo_appl_num_rel.appl_num%type := 4;
  appl_num_five                     constant demo_appl_num_rel.appl_num%type := 5;
  appl_num_six                      constant demo_appl_num_rel.appl_num%type := 6;
  
  default_amount                    constant number(17, 2) := 100;
  enough_red_quotient               demo_invest_pop_tmp.amt%type := 40;
  red_quotient_not_enough           demo_invest_pop_tmp.amt%type := 100;
  original_quotient                 demo_emp_invest.QUOTIENT%type := 50;
  original_amt                      demo_emp_invest.AMT%type := 100;

  sell_min_term                     constant number := 1;
  op_control_purchase_term_no       number;

  OUT_FLAG                          number;
  OUT_MSG                           VARCHAR2(2000);
END UT_PKG_DEMO_PROC_POP_DEAL_UNEX;
/

CREATE OR REPLACE PACKAGE BODY UT_PKG_DEMO_PROC_POP_DEAL_UNEX IS
  PROCEDURE UT_SETUP IS
  BEGIN
    OUT_FLAG := -1;
    OUT_MSG := '';
    op_control_purchase_term_no := 1;

    UT_PKG_DEMO_COMMON.create_plan_info;
    create_unex_prod_info;
  END;
  PROCEDURE UT_TEARDOWN IS
  BEGIN
    rollback;
  END;
  
  /*
  净值报价型，个人赎回
  */
  PROCEDURE UT_UNEX_EMP_ENOUGH IS
  BEGIN
    create_emp_invest_info(original_amt, original_quotient);
 
    UT_PKG_DEMO_COMMON.create_one_purchase_for_op_ctl(term_one_invest_time, op_control_purchase_term_no); 
    UT_PKG_DEMO_COMMON.create_red_pur_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
 
    UT_PKG_DEMO_COMMON.create_one_item_for_unit_value(term_one_invest_time, eval_state_flag_recent_traded); 
    UT_PKG_DEMO_COMMON.create_one_item_for_unit_value(red_term_invest_time, eval_state_flag_not_excuted);
  
    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id, subject_type_emp, enough_red_quotient);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
    
    UT_PKG_DEMO_COMMON.assert_return_success(out_flag, out_msg);
    assert_redemption_obj(subject_type_emp, emp_id);
    assert_result_count(1);
    assert_quotient_and_amt(enough_red_quotient, enough_red_quotient / original_quotient * original_amt);
  END;

  /*
  净值报价型，企业赎回
  */
  PROCEDURE UT_UNEX_CO_ENOUGH IS
  BEGIN
    create_co_invest_info(original_amt, original_quotient);

    UT_PKG_DEMO_COMMON.create_one_purchase_for_op_ctl(term_one_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_red_pur_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_one_item_for_unit_value(term_one_invest_time, eval_state_flag_recent_traded); 
    UT_PKG_DEMO_COMMON.create_one_item_for_unit_value(red_term_invest_time, eval_state_flag_not_excuted);
  
    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id_for_co, subject_type_co, enough_red_quotient);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
    
    UT_PKG_DEMO_COMMON.assert_return_success(out_flag, out_msg);
    assert_redemption_obj(subject_type_co, emp_id_for_co);
    assert_result_count(1);
    assert_quotient_and_amt(enough_red_quotient, enough_red_quotient / original_quotient * original_amt);
  END;

  /*
  净值报价型，企业赎回,不够
  */
  PROCEDURE UT_UNEX_CO_NOTENOUGH IS
  
  BEGIN
    create_co_invest_info(original_amt, original_quotient);
  
    UT_PKG_DEMO_COMMON.create_one_purchase_for_op_ctl(term_one_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_red_pur_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_one_item_for_unit_value(term_one_invest_time, eval_state_flag_recent_traded);
    UT_PKG_DEMO_COMMON.create_one_item_for_unit_value(red_term_invest_time, eval_state_flag_not_excuted);
  
    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id_for_co, subject_type_co, red_quotient_not_enough);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    UT_PKG_DEMO_COMMON.assert_out_flag_and_out_msg(out_flag, 2, out_msg, '赎回份额分配出错');
  END;

  procedure create_unex_prod_info is
  begin
    UT_PKG_DEMO_COMMON.create_prod_info(False);
  end create_unex_prod_info;

  procedure create_emp_invest_info(original_amt demo_emp_invest.QUOTIENT%type,
                                   original_quotient demo_emp_invest.AMT%type) is
  begin
    insert into demo_emp_invest
      (EMP_ID, CO_ID, SUBJECT_TYPE, INVEST_ID, AMT, QUOTIENT, SET_VALUE)
    values
      (emp_id, co_id, subject_type_emp, INVEST_ID, original_amt, original_quotient, Dummy);
  end;

  procedure create_co_invest_info(original_amt demo_emp_invest.QUOTIENT%type,
                                  original_quotient demo_emp_invest.AMT%type) is
  begin
    insert into demo_co_invest
      (CO_ID, SUBJECT_TYPE, INVEST_ID, AMT, QUOTIENT, SET_VALUE)
    values
      (co_id, subject_type_co, INVEST_ID, original_amt, original_quotient, Dummy);
  end;

  procedure assert_quotient_and_amt(expected_red_quotient demo_invest_pop_result_tmp.QUOTIENT%type,
                                    expected_amt demo_invest_pop_result_tmp.AMT%type) is
  begin
    utassert.eqqueryvalue(msg_in           => '校验quotient',
                          CHECK_QUERY_IN   => 'select quotient from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => expected_red_quotient);
    utassert.eqqueryvalue(msg_in           => '校验amt',
                          CHECK_QUERY_IN   => 'select amt from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => expected_amt);
  end;

  procedure assert_redemption_obj(expected_subject_type in demo_emp_invest.subject_type%type,
                       expected_emp_id       in demo_emp_invest.emp_id%type) is
  begin
    utassert.eqqueryvalue(msg_in           => '校验co_id',
                          CHECK_QUERY_IN   => 'select distinct co_id from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => co_id);
    utassert.eqqueryvalue(msg_in           => '校验emp_id',
                          CHECK_QUERY_IN   => 'select distinct emp_id from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => expected_emp_id);
    utassert.eqqueryvalue(msg_in           => '校验subject_type',
                          CHECK_QUERY_IN   => 'select distinct subject_type from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => expected_subject_type);
  end assert_redemption_obj;

  procedure assert_detail_by_appl(yappl_num   in number,
                                  expected_invest_time in varchar2,
                                  expected_quotient    in number,
                                  expected_amt         in number) is
  begin
    utassert.eqqueryvalue(msg_in           => '校验invest_time',
                          CHECK_QUERY_IN   => 'select invest_time from demo_invest_pop_result_tmp where YAPPL_NUM = ' ||
                                              yappl_num,
                          AGAINST_VALUE_IN => expected_invest_time);
  
    utassert.eqqueryvalue(msg_in           => '校验quotient',
                          CHECK_QUERY_IN   => 'select quotient from demo_invest_pop_result_tmp where YAPPL_NUM = ' ||
                                              yappl_num,
                          AGAINST_VALUE_IN => expected_quotient);
  
    utassert.eqqueryvalue(msg_in           => '校验amt',
                          CHECK_QUERY_IN   => 'select amt from demo_invest_pop_result_tmp where YAPPL_NUM = ' ||
                                              yappl_num,
                          AGAINST_VALUE_IN => expected_amt);
  end assert_detail_by_appl;

  procedure assert_result_count(expected_count number) is
  begin
    utassert.eqqueryvalue(msg_in           => '校验tablecount',
                          CHECK_QUERY_IN   => 'select count(1) from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => expected_count);
  end;

END UT_PKG_DEMO_PROC_POP_DEAL_UNEX;
/

set serveroutput on
/

exec utplsql.run ('UT_PKG_DEMO_PROC_POP_DEAL_UNEX', per_method_setup_in => TRUE)
/
