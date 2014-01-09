CREATE OR REPLACE PACKAGE UT_PKG_DEMO_COMMON IS
  procedure create_plan_info;
  procedure create_prod_info(buy_way in demo_invest_basic_info.BUY_WAY%type);
  procedure create_one_purchase_for_op_ctl(invest_time VARCHAR2, op_control_purchase_term_no in out number);
  procedure create_one_item_for_op_ctl(op_type number, term_no number, invest_time VARCHAR2);
  procedure create_red_pur_for_op_ctl(red_term_invest_time VARCHAR2, op_control_purchase_term_no in out number);
  procedure create_one_item_for_unit_value(evaluate_date demo_invest_unit_value.EVALUATE_DATE%type, 
                                           eval_state_flag demo_invest_unit_value.EVAL_STATE_FLAG%type);
  procedure create_invest_pop_parameters(emp_id demo_emp_invest.emp_id%type,
                                         subject_type demo_emp_invest.subject_type%type,
                                         red_amt demo_invest_pop_tmp.amt%type);

  procedure assert_out_flag_and_out_msg(out_flag number, expected_out_flag number, 
                                        out_msg VARCHAR2, expected_out_msg VARCHAR2);
  procedure assert_return_success(out_flag number, out_msg VARCHAR2);

  function one_day_before(day VARCHAR2) return VARCHAR2;

  Dummy                             constant number := 99;

  invest_id                         constant DEMO_INVEST_INFO.INVEST_ID%type := '990001';
  plan_id                           constant demo_plan_info.plan_id%type := '000001';
  co_id                             constant demo_co_invest.co_id%type := '0000001000000';
  op_type_purchase                  constant demo_invest_op_control.OP_TYPE%type := 2;
  op_type_redemption                constant demo_invest_op_control.OP_TYPE%type := 3;
  
  term_one_invest_time              constant VARCHAR2(10) := '2013-01-01';
  red_term_invest_time              constant VARCHAR2(10) := '2013-12-16';

  sell_min_term                     constant number := 1;

END UT_PKG_DEMO_COMMON;
/

CREATE OR REPLACE PACKAGE BODY UT_PKG_DEMO_COMMON IS
  procedure create_plan_info is
  begin
    insert into demo_plan_info
      (PLAN_ID, PLAN_NAME, PLAN_TIME)
    values
      (plan_id, '计划名称', '2013-12-01');
  end create_plan_info;

  procedure create_prod_info(buy_way in demo_invest_basic_info.BUY_WAY%type) is
    fpps_invest_id    demo_invest_basic_info.fpps_invest_id%type := '00000001';
    issue_way_prod    demo_invest_basic_info.ISSUE_WAY%type := 4;
  begin
    insert into demo_invest_info
      (PLAN_ID, INVEST_ID, INVEST_NAME)
    values
      (plan_id, invest_id, '组合名称');

    insert into demo_invest_basic_info
      (FPPS_INVEST_ID,
       INVEST_ID,
       INVEST_STATE,
       ISSUE_WAY,
       BUY_WAY,
       SELL_MIN_TERM,
       OPEN_SELL_TERM,
       sell_order,
       SELL_VALUE)
    values
      (fpps_invest_id, invest_id, Dummy, issue_way_prod, buy_way, sell_min_term, 1, Dummy, Dummy);
  end create_prod_info;

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

  procedure assert_out_flag_and_out_msg(out_flag number, expected_out_flag number, 
                                        out_msg VARCHAR2, expected_out_msg VARCHAR2) is
  begin
    utassert.eq(msg_in          => '校验程序返回标志',
                check_this_in   => out_flag,
                against_this_in => expected_out_flag);
    utassert.eq(msg_in          => '校验程序返回信息',
                check_this_in   => out_msg,
                against_this_in => expected_out_msg);
  end assert_out_flag_and_out_msg;

  procedure assert_return_success(out_flag number, out_msg VARCHAR2) is
  begin
    assert_out_flag_and_out_msg(out_flag, 0, out_msg, '成功');
  end assert_return_success;

  function one_day_before(day VARCHAR2) return VARCHAR2 is
  begin
    return to_char(to_date(day, 'yyyy-mm-dd') - 1, 'yyyy-mm-dd');
  end;

END UT_PKG_DEMO_COMMON;
/
