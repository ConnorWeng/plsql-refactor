CREATE OR REPLACE PACKAGE UT_PKG_DEMO_COMMON IS
  procedure create_one_purchase_for_op_ctl(invest_time VARCHAR2, op_control_purchase_term_no in out number);
  procedure create_one_item_for_op_ctl(op_type number, term_no number, invest_time VARCHAR2);
  procedure create_red_pur_for_op_ctl(red_term_invest_time VARCHAR2, op_control_purchase_term_no in out number);
  procedure create_one_item_for_unit_value(evaluate_date demo_invest_unit_value.EVALUATE_DATE%type,
                                           eval_state_flag demo_invest_unit_value.EVAL_STATE_FLAG%type);
  procedure create_invest_pop_parameters(emp_id demo_emp_invest.emp_id%type,
                                         subject_type demo_emp_invest.subject_type%type,
                                         red_amt demo_invest_pop_tmp.amt%type);
  procedure create_one_term_for_unit_val;
  procedure create_mult_term_for_unit_val;

  procedure assert_out_flag(out_flag number, expected_out_flag number);
  procedure assert_return_success(out_flag number);
  procedure assert_redemption_obj(expected_subject_type in demo_emp_invest.subject_type%type,
                                  expected_emp_id       in demo_emp_invest.emp_id%type);
  procedure assert_result_count(expected_count number);

  function one_day_before(day VARCHAR2) return VARCHAR2;

  True                              constant number := 0;
  False                             constant number := 1;
  Dummy                             constant number := 99;

  invest_id                         constant DEMO_INVEST_INFO.INVEST_ID%type := '990001';
  plan_id                           constant demo_plan_info.plan_id%type := '000001';
  co_id                             constant demo_co_invest.co_id%type := '0000001000000';
  emp_id                            constant demo_emp_invest.emp_id%type := '0000000001';
  emp_id_for_co                     constant demo_emp_invest.emp_id%type := 'FFFFFFFFFF';
  subject_type_emp                  constant demo_emp_invest.subject_type%type := '301001';
  subject_type_co                   constant demo_emp_invest.subject_type%type := '302101';
  op_type_purchase                  constant demo_invest_op_control.OP_TYPE%type := 2;
  op_type_redemption                constant demo_invest_op_control.OP_TYPE%type := 3;

  term_one_invest_time              constant VARCHAR2(10) := '2013-01-01';
  term_two_invest_time              constant VARCHAR2(10) := '2013-02-01';
  red_term_invest_time              constant VARCHAR2(10) := '2013-12-16';

  eval_state_flag_traded            constant demo_invest_unit_value.EVAL_STATE_FLAG%type := 1;
  eval_state_flag_recent_traded     constant demo_invest_unit_value.EVAL_STATE_FLAG%type := 2;
  eval_state_flag_not_excuted       constant demo_invest_unit_value.EVAL_STATE_FLAG%type := 3;

  sell_min_term                     constant number := 1;

END UT_PKG_DEMO_COMMON;
/
CREATE OR REPLACE PACKAGE BODY UT_PKG_DEMO_COMMON IS
  procedure create_one_purchase_for_op_ctl(invest_time VARCHAR2, op_control_purchase_term_no in out number) is
  begin
    create_one_item_for_op_ctl(op_type_purchase, op_control_purchase_term_no, invest_time);
    op_control_purchase_term_no := op_control_purchase_term_no + sell_min_term;
  end create_one_purchase_for_op_ctl;

  procedure create_one_item_for_op_ctl(op_type number, term_no number, invest_time VARCHAR2) is
  begin
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (invest_id, op_type, term_no, invest_time);
  end create_one_item_for_op_ctl;

  procedure create_red_pur_for_op_ctl(red_term_invest_time VARCHAR2, op_control_purchase_term_no in out number) is
  begin
    create_one_item_for_op_ctl(op_type_redemption, 1, one_day_before(red_term_invest_time));
    create_one_purchase_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
  end;

  procedure create_one_item_for_unit_value(evaluate_date demo_invest_unit_value.EVALUATE_DATE%type,
                                           eval_state_flag demo_invest_unit_value.EVAL_STATE_FLAG%type) is
  begin
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (invest_id, evaluate_date, plan_id, Dummy, eval_state_flag);
  end create_one_item_for_unit_value;

  procedure create_invest_pop_parameters(emp_id demo_emp_invest.emp_id%type,
                                         subject_type demo_emp_invest.subject_type%type,
                                         red_amt demo_invest_pop_tmp.amt%type) is
  begin
    insert into demo_invest_pop_tmp
      (EMP_ID, CO_ID, SUBJECT_TYPE, AMT)
    values
      (emp_id, co_id, subject_type, red_amt);
  end;

  procedure create_one_term_for_unit_val is
  begin
    create_one_item_for_unit_value(term_one_invest_time, eval_state_flag_recent_traded);
    create_one_item_for_unit_value(red_term_invest_time, eval_state_flag_not_excuted);
  end;

  procedure create_mult_term_for_unit_val is
  begin
    create_one_item_for_unit_value(term_one_invest_time, eval_state_flag_traded);
    create_one_item_for_unit_value(term_two_invest_time, eval_state_flag_recent_traded);
    create_one_item_for_unit_value(red_term_invest_time, eval_state_flag_not_excuted);
  end;

  procedure assert_out_flag(out_flag number, expected_out_flag number) is
  begin
    utassert.eq(msg_in          => '校验程序返回标志',
                check_this_in   => out_flag,
                against_this_in => expected_out_flag);
  end assert_out_flag;

  procedure assert_return_success(out_flag number) is
  begin
    assert_out_flag(out_flag, 0);
  end assert_return_success;

  procedure assert_redemption_obj(expected_subject_type in demo_emp_invest.subject_type%type,
                                  expected_emp_id       in demo_emp_invest.emp_id%type) is
  begin
    utassert.eqqueryvalue(msg_in           => '校验co_id',
                          CHECK_QUERY_IN   => 'select distinct co_id from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => co_id);
    utassert.eqqueryvalue(msg_in           => '校验emp_id',
                          CHECK_QUERY_IN   => 'select distinct emp_id from demo_invest_pop_result_tmp where emp_id = ''' || expected_emp_id || '''',
                          AGAINST_VALUE_IN => expected_emp_id);
    utassert.eqqueryvalue(msg_in           => '校验subject_type',
                          CHECK_QUERY_IN   => 'select distinct subject_type from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => expected_subject_type);
  end assert_redemption_obj;

  procedure assert_result_count(expected_count number) is
  begin
    utassert.eqqueryvalue(msg_in           => '校验tablecount',
                          CHECK_QUERY_IN   => 'select count(1) from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => expected_count);
  end;

  function one_day_before(day VARCHAR2) return VARCHAR2 is
  begin
    return to_char(to_date(day, 'yyyy-mm-dd') - 1, 'yyyy-mm-dd');
  end;

END UT_PKG_DEMO_COMMON;
/

set serveroutput on
/

BEGIN
  utSuite.add ('UT_PKG_DEMO_PROC_POP_DEAL');
  utPackage.add ('UT_PKG_DEMO_PROC_POP_DEAL', 'UT_PKG_DEMO_PROC_POP_DEAL_EX');
  utPackage.add ('UT_PKG_DEMO_PROC_POP_DEAL', 'UT_PKG_DEMO_PROC_POP_DEAL_UNEX');
  utPLSQL.runsuite ('UT_PKG_DEMO_PROC_POP_DEAL', per_method_setup_in => TRUE);
END;
/

select last_status from ut_suite where name = 'UT_PKG_DEMO_PROC_POP_DEAL';
