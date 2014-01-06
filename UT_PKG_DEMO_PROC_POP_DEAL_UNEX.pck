CREATE OR REPLACE PACKAGE UT_PKG_DEMO_PROC_POP_DEAL_UNEX IS
  PROCEDURE UT_SETUP;
  PROCEDURE UT_TEARDOWN;

  PROCEDURE UT_UNEX_EMP_ENOUGH;
  PROCEDURE UT_UNEX_CO_ENOUGH;
  PROCEDURE UT_UNEX_CO_NOTENOUGH;

  procedure create_unex_prod_info;
  procedure create_invest_pop_parameters(emp_id demo_emp_invest.emp_id%type,
                                         subject_type demo_emp_invest.subject_type%type,
                                         red_amt demo_invest_pop_tmp.amt%type);
  
  procedure assert_redemption_obj(expected_subject_type in demo_emp_invest.subject_type%type,
                                  expected_emp_id       in demo_emp_invest.emp_id%type);
  procedure assert_return_success;
  procedure assert_out_flag_and_out_msg(expected_out_flag number, expected_out_msg VARCHAR2);
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
    v_red_amt              demo_invest_pop_tmp.amt%type := 50;
  BEGIN
    --账务数据
    insert into demo_emp_invest
      (EMP_ID, CO_ID, SUBJECT_TYPE, INVEST_ID, AMT, QUOTIENT, SET_VALUE)
    values
      (emp_id, co_id, subject_type_emp, INVEST_ID, 50, 50, 100);
 
    UT_PKG_DEMO_COMMON.create_one_purchase_for_op_ctl(term_one_invest_time, op_control_purchase_term_no); 
    UT_PKG_DEMO_COMMON.create_red_pur_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
 
    UT_PKG_DEMO_COMMON.create_one_item_for_unit_value(term_one_invest_time, eval_state_flag_recent_traded); 
    UT_PKG_DEMO_COMMON.create_one_item_for_unit_value(red_term_invest_time, eval_state_flag_not_excuted);
  
    create_invest_pop_parameters(emp_id, subject_type_emp, v_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
    
    assert_return_success;
    assert_redemption_obj(subject_type_emp, emp_id);
    assert_result_count(1);
  
    --校验quotient
    utassert.eqqueryvalue(msg_in           => 'check quotient',
                          CHECK_QUERY_IN   => 'select quotient from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => 50);
  
    --校验amt
    utassert.eqqueryvalue(msg_in           => 'check amt',
                          CHECK_QUERY_IN   => 'select amt from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => 50);
  
  END;
  /*
  净值报价型，企业赎回
  */
  PROCEDURE UT_UNEX_CO_ENOUGH IS
    --out arguements definition
    v_term_one_invest_time VARCHAR2(10) := '2013-01-01';
    v_red_term_invest_time VARCHAR2(10) := '2013-12-16';
    v_red_amt              demo_invest_pop_tmp.amt%type := 50;
  
  BEGIN
    --准备数据
    --预期收益产品准备
    --账务数据
    insert into demo_co_invest
      (CO_ID, SUBJECT_TYPE, INVEST_ID, AMT, QUOTIENT, SET_VALUE)
    values
      (co_id, subject_type_co, INVEST_ID, 50, 50, 100);
  
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (invest_id, 2, 1, v_term_one_invest_time);
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (invest_id,
       3,
       1,
       to_char(to_date(v_red_term_invest_time, 'yyyy-mm-dd') - 1,
               'yyyy-mm-dd'));
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (invest_id, 2, 12, v_red_term_invest_time);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (invest_id, v_term_one_invest_time, plan_id, 1, 2);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (invest_id, v_red_term_invest_time, plan_id, 1, 3);
  
    --传入数据
    insert into demo_invest_pop_tmp
      (EMP_ID, CO_ID, SUBJECT_TYPE, AMT)
    values
      (emp_id_for_co, co_id, subject_type_co, v_red_amt);
  
    --执行被测代码
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
    --执行asserts
    --校验程序返回标志
    assert_return_success;
  
    --校验拆分对象
    assert_redemption_obj(subject_type_co, emp_id_for_co );
  
    --校验tablecount
    utassert.eqqueryvalue(msg_in           => 'check tablecount',
                          CHECK_QUERY_IN   => 'select count(1) from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => 1);
  
    --校验quotient
    utassert.eqqueryvalue(msg_in           => 'check quotient',
                          CHECK_QUERY_IN   => 'select quotient from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => 50);
  
    --校验amt
    utassert.eqqueryvalue(msg_in           => 'check amt',
                          CHECK_QUERY_IN   => 'select amt from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => 50);
  
  END;
  /*
  净值报价型，企业赎回,不够
  */
  PROCEDURE UT_UNEX_CO_NOTENOUGH IS
    --out arguements definition
    v_term_one_invest_time VARCHAR2(10) := '2013-01-01';
    v_red_term_invest_time VARCHAR2(10) := '2013-12-16';
    v_red_amt              demo_invest_pop_tmp.amt%type := 100;
  
  BEGIN
    --准备数据
    --预期收益产品准备
    --账务数据
    insert into demo_co_invest
      (CO_ID, SUBJECT_TYPE, INVEST_ID, AMT, QUOTIENT, SET_VALUE)
    values
      (co_id, subject_type_co, INVEST_ID, 50, 50, 100);
  
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (invest_id, 2, 1, v_term_one_invest_time);
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (invest_id,
       3,
       1,
       to_char(to_date(v_red_term_invest_time, 'yyyy-mm-dd') - 1,
               'yyyy-mm-dd'));
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (invest_id, 2, 12, v_red_term_invest_time);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (invest_id, v_term_one_invest_time, plan_id, 1, 2);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (invest_id, v_red_term_invest_time, plan_id, 1, 3);
  
    --传入数据
    insert into demo_invest_pop_tmp
      (EMP_ID, CO_ID, SUBJECT_TYPE, AMT)
    values
      (emp_id_for_co, co_id, subject_type_co, v_red_amt);
  
    --执行被测代码
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    assert_out_flag_and_out_msg(2, '赎回份额分配出错');
  
  END;

  procedure create_unex_prod_info is
  begin
    UT_PKG_DEMO_COMMON.create_prod_info(False);
  end create_unex_prod_info;

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

  procedure assert_return_success is
  begin
    assert_out_flag_and_out_msg(0, '成功');
  end assert_return_success;

  procedure assert_out_flag_and_out_msg(expected_out_flag number, expected_out_msg VARCHAR2) is
  begin
    utassert.eq(msg_in          => '校验程序返回标志',
                check_this_in   => out_flag,
                against_this_in => expected_out_flag);
    utassert.eq(msg_in          => '校验程序返回信息',
                check_this_in   => out_msg,
                against_this_in => expected_out_msg);
  end assert_out_flag_and_out_msg;

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

  procedure create_invest_pop_parameters(emp_id demo_emp_invest.emp_id%type,
                                         subject_type demo_emp_invest.subject_type%type,
                                         red_amt demo_invest_pop_tmp.amt%type) is
  begin
    insert into demo_invest_pop_tmp
      (EMP_ID, CO_ID, SUBJECT_TYPE, AMT)
    values
      (emp_id, co_id, subject_type, red_amt);
  end;

END UT_PKG_DEMO_PROC_POP_DEAL_UNEX;
/

set serveroutput on
/

exec utplsql.run ('UT_PKG_DEMO_PROC_POP_DEAL_UNEX', per_method_setup_in => TRUE)
/
