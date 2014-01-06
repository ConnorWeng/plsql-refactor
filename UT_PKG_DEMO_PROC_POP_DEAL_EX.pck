CREATE OR REPLACE PACKAGE UT_PKG_DEMO_PROC_POP_DEAL_EX IS
  PROCEDURE UT_SETUP;
  PROCEDURE UT_TEARDOWN;

  PROCEDURE UT_EX_EMP_ONE_TERM_ONE_APPL;
  PROCEDURE UT_EX_EMP_MULT_TERM_ONE_APPL;
  PROCEDURE UT_EX_EMP_MULT_TERM_MULT_APPL;
  PROCEDURE UT_EX_EMP_MULT_TERM_NOTENOUGH;
  PROCEDURE UT_EX_CO_MULT_TERM;
  PROCEDURE UT_EX_CO_MAX_FIVE_APPL;

  procedure create_plan_info;
  procedure create_ex_prod_info;
  procedure create_prod_info(buy_way in demo_invest_basic_info.BUY_WAY%type);
  procedure create_one_term_acct_for_emp(appl_num     in demo_appl_num_rel.appl_num%type,
                                         invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                         amt          in demo_appl_num_rel.AMT%type);
  procedure create_one_term_acct_for_co(appl_num     in demo_appl_num_rel.appl_num%type,
                                        invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                        amt          in demo_appl_num_rel.AMT%type);
  procedure create_invest_pop_parameters(emp_id demo_emp_invest.emp_id%type,
                                         subject_type demo_emp_invest.subject_type%type,
                                         red_amt demo_invest_pop_tmp.amt%type);
  procedure create_one_purchase_for_op_ctl(invest_time VARCHAR2);
  procedure create_one_red_for_op_ctl(term_no number, invest_time VARCHAR2);
  procedure create_one_item_for_op_ctl(op_type number, term_no number, invest_time VARCHAR2);
  procedure create_red_pur_for_op_ctl(red_term_invest_time VARCHAR2);
  procedure create_one_item_for_unit_value(evaluate_date demo_invest_unit_value.EVALUATE_DATE%type, 
                                           eval_state_flag demo_invest_unit_value.EVAL_STATE_FLAG%type);
  
  procedure assert_redemption_obj(expected_subject_type in demo_emp_invest.subject_type%type,
                                  expected_emp_id       in demo_emp_invest.emp_id%type);
  procedure assert_return_success;
  procedure assert_out_flag_and_out_msg(expected_out_flag number, expected_out_msg VARCHAR2);
  procedure assert_detail_by_appl(yappl_num   in number,
                                  expected_invest_time in varchar2,
                                  expected_quotient    in number,
                                  expected_amt         in number);
  procedure assert_result_count;

  function one_day_before(day VARCHAR2) return VARCHAR2;

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
  
  term_one_invest_time              constant VARCHAR2(10) := '2013-01-01';
  term_two_invest_time              constant VARCHAR2(10) := '2013-02-01';
  red_term_invest_time              constant VARCHAR2(10) := '2013-12-16';

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
END UT_PKG_DEMO_PROC_POP_DEAL_EX;
/

CREATE OR REPLACE PACKAGE BODY UT_PKG_DEMO_PROC_POP_DEAL_EX IS
  PROCEDURE UT_SETUP IS
  BEGIN
    OUT_FLAG := -1;
    OUT_MSG := '';
    op_control_purchase_term_no := 1;

    create_plan_info;
    create_ex_prod_info;

    create_one_purchase_for_op_ctl(term_one_invest_time);
    create_one_purchase_for_op_ctl(term_two_invest_time);
    create_red_pur_for_op_ctl(red_term_invest_time);
  END;
  PROCEDURE UT_TEARDOWN IS
  BEGIN
    rollback;
  END;
  
  /*
  涉及一期，且一期只有一张申请单，一期资产够（个人）
  */
  PROCEDURE UT_EX_EMP_ONE_TERM_ONE_APPL IS
    red_amt              demo_invest_pop_tmp.amt%type := 90;
  
  BEGIN
    create_one_term_acct_for_emp(appl_num_one, term_one_invest_time, red_amt);
  
    create_one_item_for_unit_value(term_one_invest_time, eval_state_flag_recent_traded);
    create_one_item_for_unit_value(red_term_invest_time, eval_state_flag_not_excuted);
  
    create_invest_pop_parameters(emp_id, subject_type_emp, red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => invest_id,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
  
    assert_return_success;
    assert_redemption_obj(subject_type_emp, emp_id);
    assert_result_count;
    assert_detail_by_appl(appl_num_one, term_one_invest_time, red_amt, red_amt);
  END;

  /*
  涉及一期，且一期只有一张申请单，一期资产够（个人）
  */
  PROCEDURE UT_EX_EMP_MULT_TERM_ONE_APPL IS
    v_red_amt              demo_invest_pop_tmp.amt%type := 180;
  BEGIN
    create_one_term_acct_for_emp(appl_num_one, term_one_invest_time, default_amount);
    create_one_term_acct_for_emp(appl_num_two, term_two_invest_time, default_amount);
  

    create_one_item_for_unit_value(term_one_invest_time, eval_state_flag_traded);
    create_one_item_for_unit_value(term_two_invest_time, eval_state_flag_recent_traded);
    create_one_item_for_unit_value(red_term_invest_time, eval_state_flag_not_excuted);
 
    create_invest_pop_parameters(emp_id, subject_type_emp, v_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
  
    assert_return_success;
    assert_redemption_obj(subject_type_emp, emp_id);
    assert_detail_by_appl(appl_num_one, term_one_invest_time, v_red_amt - default_amount, v_red_amt - default_amount);
    assert_detail_by_appl(appl_num_two, term_two_invest_time, default_amount, default_amount);
  
  END;

  /*
  涉及多期，且多期只有多张申请单，多期资产够（个人）
  */
  PROCEDURE UT_EX_EMP_MULT_TERM_MULT_APPL IS
    v_red_amt              demo_invest_pop_tmp.amt%type := 250;
  BEGIN
    create_one_term_acct_for_emp(appl_num_one, term_one_invest_time, default_amount);
    create_one_term_acct_for_emp(appl_num_two, term_two_invest_time, default_amount);
    create_one_term_acct_for_emp(appl_num_three, term_one_invest_time, default_amount);
 
 
    create_one_item_for_unit_value(term_one_invest_time, eval_state_flag_traded);
    create_one_item_for_unit_value(term_two_invest_time, eval_state_flag_recent_traded);
    create_one_item_for_unit_value(red_term_invest_time, eval_state_flag_not_excuted);

    create_invest_pop_parameters(emp_id, subject_type_emp, v_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
  
    assert_return_success;
    assert_redemption_obj(subject_type_emp, emp_id);
    assert_detail_by_appl(appl_num_one, term_one_invest_time, default_amount, default_amount);
    assert_detail_by_appl(appl_num_two, term_two_invest_time, default_amount, default_amount);
    assert_detail_by_appl(appl_num_three, term_one_invest_time, v_red_amt - default_amount * 2, v_red_amt - default_amount * 2);
  
  END;

  /*
  涉及多期，且多期只有多张申请单，多期资产够（个人）
  */
  PROCEDURE UT_EX_EMP_MULT_TERM_NOTENOUGH IS
    v_red_amt              demo_invest_pop_tmp.amt%type := 310;
  
  BEGIN
    create_one_term_acct_for_emp(appl_num_one, term_one_invest_time, default_amount);
    create_one_term_acct_for_emp(appl_num_two, term_two_invest_time, default_amount);
    create_one_term_acct_for_emp(appl_num_three, term_one_invest_time, default_amount);
 
 
    create_one_item_for_unit_value(term_one_invest_time, eval_state_flag_traded); 
    create_one_item_for_unit_value(term_two_invest_time, eval_state_flag_recent_traded);
    create_one_item_for_unit_value(red_term_invest_time, eval_state_flag_not_excuted);
  
    create_invest_pop_parameters(emp_id, subject_type_emp, v_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    assert_out_flag_and_out_msg(2, '进行后进先出处理时，资产不足');
  END;

  /*
  涉及多期，且多期只有多张申请单，多期资产够（企业）
  */
  PROCEDURE UT_EX_CO_MULT_TERM IS
    v_red_amt              demo_invest_pop_tmp.amt%type := 250;
  
  BEGIN
    create_one_term_acct_for_co(appl_num_one, term_one_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_two, term_two_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_three, term_one_invest_time, default_amount);
 
 
    create_one_item_for_unit_value(term_one_invest_time, eval_state_flag_traded);
    create_one_item_for_unit_value(term_two_invest_time, eval_state_flag_recent_traded);
    create_one_item_for_unit_value(red_term_invest_time, eval_state_flag_not_excuted); 
  
    create_invest_pop_parameters(emp_id_for_co, subject_type_co, v_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
  
    assert_return_success;
    assert_redemption_obj(subject_type_co, emp_id_for_co);
    assert_detail_by_appl(appl_num_one, term_one_invest_time, default_amount, default_amount);
    assert_detail_by_appl(appl_num_two, term_two_invest_time, default_amount, default_amount);
    assert_detail_by_appl(appl_num_three, term_one_invest_time, v_red_amt - default_amount * 2, v_red_amt - default_amount * 2);
  
  END;

  /*
  赎回涉及超过五张申请单（企业）
  */
  PROCEDURE UT_EX_CO_MAX_FIVE_APPL IS
    v_red_amt              demo_invest_pop_tmp.amt%type := 600;
  
  BEGIN
    create_one_term_acct_for_co(appl_num_one, term_one_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_two, term_two_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_three, term_one_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_four, term_one_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_five, term_one_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_six, term_one_invest_time, default_amount);
    
 
    create_one_item_for_unit_value(term_one_invest_time, eval_state_flag_traded);
    create_one_item_for_unit_value(term_two_invest_time, eval_state_flag_recent_traded);
    create_one_item_for_unit_value(red_term_invest_time, eval_state_flag_not_excuted); 
  
    create_invest_pop_parameters(emp_id_for_co, subject_type_co, v_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
  
    assert_out_flag_and_out_msg(3, '企业：' ||
                                   PKG_DEMO_COMMON.FUNC_GET_COFNAMEBYID(co_id) ||
                                   '生成申请单超过5条');
    assert_detail_by_appl(appl_num_one, term_one_invest_time, default_amount, default_amount);
    assert_detail_by_appl(appl_num_two, term_two_invest_time, default_amount, default_amount);
    assert_detail_by_appl(appl_num_three, term_one_invest_time, default_amount, default_amount);
    assert_detail_by_appl(appl_num_four, term_one_invest_time, default_amount, default_amount);
    assert_detail_by_appl(appl_num_five, term_one_invest_time, default_amount, default_amount);
    assert_detail_by_appl(appl_num_six, term_one_invest_time, default_amount, default_amount);
  
  END;

  procedure create_plan_info is
  begin
    insert into demo_plan_info
      (PLAN_ID, PLAN_NAME, PLAN_TIME)
    values
      (plan_id, '计划名称', '2013-12-01');
  end create_plan_info;

  procedure create_ex_prod_info is
  begin
    create_prod_info(True);
  end create_ex_prod_info;

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

  procedure assert_result_count is
  begin
    utassert.eqqueryvalue(msg_in           => '校验tablecount',
                          CHECK_QUERY_IN   => 'select count(1) from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => 1);
  end;

  procedure create_one_term_acct_for_emp(appl_num     in demo_appl_num_rel.appl_num%type,
                                       invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                       amt          in demo_appl_num_rel.AMT%type) is
  begin
    insert into demo_appl_num_rel
      (CO_ID, INVEST_ID, APPL_NUM, INVEST_TIME, AMT, RED_AMT)
    values
      (co_id, invest_id, appl_num, invest_time, amt, 0.00);
  
    merge into demo_emp_invest a
    using (select emp_id       emp_id,
                  co_id        co_id,
                  subject_type_emp subject_type,
                  invest_id    invest_id,
                  amt          amt
             from dual) b
    on (a.emp_id = b.emp_id and a.co_id = b.co_id and a.subject_type = b.subject_type and a.invest_id = b.invest_id)
    WHEN MATCHED THEN
      UPDATE
         SET A.AMT       = a.AMT + b.amt,
             a.quotient  = a.quotient + b.amt,
             a.set_value = a.set_value + b.amt
    when not matched then
      insert
        (EMP_ID, CO_ID, SUBJECT_TYPE, INVEST_ID, AMT, QUOTIENT, SET_VALUE)
      values
        (b.emp_id,
         b.co_id,
         b.subject_type,
         b.invest_id,
         b.amt,
         b.amt,
         b.amt);
  
    merge into demo_emp_invest_term a
    using (select emp_id       emp_id,
                  co_id        co_id,
                  subject_type_emp subject_type,
                  invest_id    invest_id,
                  invest_time  invest_time,
                  amt          amt
             from dual) b
    on (a.emp_id = b.emp_id and a.co_id = b.co_id and a.subject_type = b.subject_type and a.invest_id = b.invest_id and a.invest_time = b.invest_time)
    WHEN MATCHED THEN
      UPDATE SET A.AMT = a.AMT + b.amt
    when not matched then
      insert
        (EMP_ID, CO_ID, SUBJECT_TYPE, INVEST_ID, invest_time, AMT)
      values
        (b.emp_id,
         b.co_id,
         b.subject_type,
         b.invest_id,
         b.invest_time,
         b.amt);
  
  end create_one_term_acct_for_emp;

  procedure create_one_term_acct_for_co(appl_num     in demo_appl_num_rel.appl_num%type,
                                        invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                        amt          in demo_appl_num_rel.AMT%type) is
  begin
    insert into demo_appl_num_rel
      (CO_ID, INVEST_ID, APPL_NUM, INVEST_TIME, AMT, RED_AMT)
    values
      (co_id, invest_id, appl_num, invest_time, amt, 0.00);
  
    merge into demo_co_invest a
    using (select co_id        co_id,
                  subject_type_co subject_type,
                  invest_id    invest_id,
                  amt          amt
             from dual) b
    on (a.co_id = b.co_id and a.subject_type = b.subject_type and a.invest_id = b.invest_id)
    WHEN MATCHED THEN
      UPDATE
         SET A.AMT       = a.AMT + b.amt,
             a.quotient  = a.quotient + b.amt,
             a.set_value = a.set_value + b.amt
    when not matched then
      insert
        (CO_ID, SUBJECT_TYPE, INVEST_ID, AMT, QUOTIENT, SET_VALUE)
      values
        (b.co_id, b.subject_type, b.invest_id, b.amt, b.amt, b.amt);
  
    merge into demo_co_invest_term a
    using (select co_id        co_id,
                  subject_type_co subject_type,
                  invest_id    invest_id,
                  invest_time  invest_time,
                  amt          amt
             from dual) b
    on (a.co_id = b.co_id and a.subject_type = b.subject_type and a.invest_id = b.invest_id and a.invest_time = b.invest_time)
    WHEN MATCHED THEN
      UPDATE SET A.AMT = a.AMT + b.amt
    when not matched then
      insert
        (CO_ID, SUBJECT_TYPE, INVEST_ID, invest_time, AMT)
      values
        (b.co_id, b.subject_type, b.invest_id, b.invest_time, b.amt);
  
  end create_one_term_acct_for_co;

  procedure create_invest_pop_parameters(emp_id demo_emp_invest.emp_id%type,
                                         subject_type demo_emp_invest.subject_type%type,
                                         red_amt demo_invest_pop_tmp.amt%type) is
  begin
    insert into demo_invest_pop_tmp
      (EMP_ID, CO_ID, SUBJECT_TYPE, AMT)
    values
      (emp_id, co_id, subject_type, red_amt);
  end;

  procedure create_one_purchase_for_op_ctl(invest_time VARCHAR2) is
  begin
    create_one_item_for_op_ctl(op_type_purchase, op_control_purchase_term_no, invest_time);
    op_control_purchase_term_no := op_control_purchase_term_no + sell_min_term;
  end create_one_purchase_for_op_ctl;

  procedure create_one_red_for_op_ctl(term_no number, invest_time VARCHAR2) is
  begin
    create_one_item_for_op_ctl(op_type_redemption, term_no, invest_time);
  end create_one_red_for_op_ctl;

  procedure create_one_item_for_op_ctl(op_type number, term_no number, invest_time VARCHAR2) is
  begin
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (invest_id, op_type, term_no, invest_time);
  end create_one_item_for_op_ctl;

  procedure create_one_item_for_unit_value(evaluate_date demo_invest_unit_value.EVALUATE_DATE%type, 
                                           eval_state_flag demo_invest_unit_value.EVAL_STATE_FLAG%type) is
  begin
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (invest_id, evaluate_date, plan_id, Dummy, eval_state_flag);
  end create_one_item_for_unit_value;

  procedure create_red_pur_for_op_ctl(red_term_invest_time VARCHAR2) is
  begin
    create_one_red_for_op_ctl(1, one_day_before(red_term_invest_time));
    create_one_purchase_for_op_ctl(red_term_invest_time);
  end;

  function one_day_before(day VARCHAR2) return VARCHAR2 is
  begin
    return to_char(to_date(day, 'yyyy-mm-dd') - 1, 'yyyy-mm-dd');
  end;
END UT_PKG_DEMO_PROC_POP_DEAL_EX;
/

set serveroutput on
/

exec utplsql.run ('UT_PKG_DEMO_PROC_POP_DEAL_EX', per_method_setup_in => TRUE)
/
