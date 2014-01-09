CREATE OR REPLACE PACKAGE UT_PKG_DEMO_PROC_POP_DEAL_EX IS
  PROCEDURE UT_SETUP;
  PROCEDURE UT_TEARDOWN;

  PROCEDURE UT_EX_EMP_ONE_TERM_ONE_APPL;
  PROCEDURE UT_EX_EMP_MULT_TERM_ONE_APPL;
  PROCEDURE UT_EX_EMP_MULT_TERM_MULT_APPL;
  PROCEDURE UT_EX_EMP_MULT_TERM_NOTENOUGH;
  PROCEDURE UT_EX_CO_MULT_TERM;
  PROCEDURE UT_EX_CO_MAX_FIVE_APPL;

  procedure create_ex_prod_info;
  procedure create_one_term_acct_for_emp(appl_num     in demo_appl_num_rel.appl_num%type,
                                         invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                         amt          in demo_appl_num_rel.AMT%type);
  procedure create_one_term_acct_for_co(appl_num     in demo_appl_num_rel.appl_num%type,
                                        invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                        amt          in demo_appl_num_rel.AMT%type);
  procedure create_one_appl_num_rel(appl_num     in demo_appl_num_rel.appl_num%type,
                                    invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                    amt          in demo_appl_num_rel.AMT%type);
  procedure create_mult_term_for_unit_val;
  
  procedure assert_detail_by_appl(yappl_num   in number,
                                  expected_invest_time in varchar2,
                                  expected_amt         in number);

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
  one_term_one_appl_red_amt         constant demo_invest_pop_tmp.amt%type := 90;
  mult_term_one_appl_red_amt        constant demo_invest_pop_tmp.amt%type := 180;
  mult_term_mult_appl_red_amt       constant demo_invest_pop_tmp.amt%type := 250;
  not_enough_red_amt                constant demo_invest_pop_tmp.amt%type := 310;
  enough_red_amt_for_over_five      constant demo_invest_pop_tmp.amt%type := 580;

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

    UT_PKG_DEMO_COMMON.create_plan_info;
    create_ex_prod_info;

    UT_PKG_DEMO_COMMON.create_one_purchase_for_op_ctl(term_one_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_one_purchase_for_op_ctl(term_two_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_red_pur_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
  END;

  PROCEDURE UT_TEARDOWN IS
  BEGIN
    rollback;
  END;
  
  /*
  涉及一期，且一期只有一张申请单，一期资产够（个人）
  */
  PROCEDURE UT_EX_EMP_ONE_TERM_ONE_APPL IS
  BEGIN
    UT_PKG_DEMO_COMMON.create_one_term_for_unit_val;
    create_one_term_acct_for_emp(appl_num_one, term_one_invest_time, one_term_one_appl_red_amt);

    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id, subject_type_emp, one_term_one_appl_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => invest_id,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
  
    UT_PKG_DEMO_COMMON.assert_return_success(out_flag, out_msg);
    UT_PKG_DEMO_COMMON.assert_redemption_obj(subject_type_emp, emp_id);
    UT_PKG_DEMO_COMMON.assert_result_count(1);
    assert_detail_by_appl(appl_num_one, term_one_invest_time, one_term_one_appl_red_amt);
  END;

  /*
  涉及一期，且一期只有一张申请单，一期资产够（个人）
  */
  PROCEDURE UT_EX_EMP_MULT_TERM_ONE_APPL IS
  BEGIN
    create_mult_term_for_unit_val;
    create_one_term_acct_for_emp(appl_num_one, term_one_invest_time, default_amount);
    create_one_term_acct_for_emp(appl_num_two, term_two_invest_time, default_amount);
 
    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id, subject_type_emp, mult_term_one_appl_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
  
    UT_PKG_DEMO_COMMON.assert_return_success(out_flag, out_msg);
    UT_PKG_DEMO_COMMON.assert_redemption_obj(subject_type_emp, emp_id);
    UT_PKG_DEMO_COMMON.assert_result_count(2);
    assert_detail_by_appl(appl_num_one, term_one_invest_time, mult_term_one_appl_red_amt - default_amount);
    assert_detail_by_appl(appl_num_two, term_two_invest_time, default_amount);
  END;

  /*
  涉及多期，且多期只有多张申请单，多期资产够（个人）
  */
  PROCEDURE UT_EX_EMP_MULT_TERM_MULT_APPL IS
  BEGIN
    create_mult_term_for_unit_val;
    create_one_term_acct_for_emp(appl_num_one, term_one_invest_time, default_amount);
    create_one_term_acct_for_emp(appl_num_two, term_two_invest_time, default_amount);
    create_one_term_acct_for_emp(appl_num_three, term_one_invest_time, default_amount);

    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id, subject_type_emp, mult_term_mult_appl_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
  
    UT_PKG_DEMO_COMMON.assert_return_success(out_flag, out_msg);
    UT_PKG_DEMO_COMMON.assert_redemption_obj(subject_type_emp, emp_id);
    UT_PKG_DEMO_COMMON.assert_result_count(3);
    assert_detail_by_appl(appl_num_one, term_one_invest_time, default_amount);
    assert_detail_by_appl(appl_num_two, term_two_invest_time, default_amount);
    assert_detail_by_appl(appl_num_three, term_one_invest_time, mult_term_mult_appl_red_amt - default_amount * 2);
  END;

  /*
  涉及多期，且多期只有多张申请单，多期资产够（个人）
  */
  PROCEDURE UT_EX_EMP_MULT_TERM_NOTENOUGH IS
  BEGIN
    create_mult_term_for_unit_val;
    create_one_term_acct_for_emp(appl_num_one, term_one_invest_time, default_amount);
    create_one_term_acct_for_emp(appl_num_two, term_two_invest_time, default_amount);
    create_one_term_acct_for_emp(appl_num_three, term_one_invest_time, default_amount);
  
    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id, subject_type_emp, not_enough_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    UT_PKG_DEMO_COMMON.assert_out_flag_and_out_msg(out_flag, 2, out_msg, '进行后进先出处理时，资产不足');
  END;

  /*
  涉及多期，且多期只有多张申请单，多期资产够（企业）
  */
  PROCEDURE UT_EX_CO_MULT_TERM IS
  BEGIN
    create_mult_term_for_unit_val;
    create_one_term_acct_for_co(appl_num_one, term_one_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_two, term_two_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_three, term_one_invest_time, default_amount);
  
    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id_for_co, subject_type_co, mult_term_mult_appl_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
  
    UT_PKG_DEMO_COMMON.assert_return_success(out_flag, out_msg);
    UT_PKG_DEMO_COMMON.assert_redemption_obj(subject_type_co, emp_id_for_co);
    UT_PKG_DEMO_COMMON.assert_result_count(3);
    assert_detail_by_appl(appl_num_one, term_one_invest_time, default_amount);
    assert_detail_by_appl(appl_num_two, term_two_invest_time, default_amount);
    assert_detail_by_appl(appl_num_three, term_one_invest_time, mult_term_mult_appl_red_amt - default_amount * 2);
  END;

  /*
  赎回涉及超过五张申请单（企业）
  */
  PROCEDURE UT_EX_CO_MAX_FIVE_APPL IS
  BEGIN
    create_mult_term_for_unit_val;
    create_one_term_acct_for_co(appl_num_one, term_one_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_two, term_two_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_three, term_one_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_four, term_one_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_five, term_one_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_six, term_one_invest_time, default_amount);
  
    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id_for_co, subject_type_co, enough_red_amt_for_over_five);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
  
    UT_PKG_DEMO_COMMON.assert_out_flag_and_out_msg(out_flag, 3, out_msg, '企业：' ||
                                   PKG_DEMO_COMMON.FUNC_GET_COFNAMEBYID(co_id) ||
                                   '生成申请单超过5条');
    UT_PKG_DEMO_COMMON.assert_result_count(6);
    assert_detail_by_appl(appl_num_one, term_one_invest_time, default_amount);
    assert_detail_by_appl(appl_num_two, term_two_invest_time, default_amount);
    assert_detail_by_appl(appl_num_three, term_one_invest_time, default_amount);
    assert_detail_by_appl(appl_num_four, term_one_invest_time, default_amount);
    assert_detail_by_appl(appl_num_five, term_one_invest_time, default_amount);
    assert_detail_by_appl(appl_num_six, term_one_invest_time, enough_red_amt_for_over_five - default_amount * 5);
  END;

  procedure create_ex_prod_info is
  begin
    UT_PKG_DEMO_COMMON.create_prod_info(True);
  end create_ex_prod_info;

  procedure assert_detail_by_appl(yappl_num   in number,
                                  expected_invest_time in varchar2,
                                  expected_amt         in number) is
  begin
    utassert.eqqueryvalue(msg_in           => '校验invest_time',
                          CHECK_QUERY_IN   => 'select invest_time from demo_invest_pop_result_tmp where YAPPL_NUM = ' ||
                                              yappl_num,
                          AGAINST_VALUE_IN => expected_invest_time);
  
    utassert.eqqueryvalue(msg_in           => '校验quotient',
                          CHECK_QUERY_IN   => 'select quotient from demo_invest_pop_result_tmp where YAPPL_NUM = ' ||
                                              yappl_num,
                          AGAINST_VALUE_IN => expected_amt);
  
    utassert.eqqueryvalue(msg_in           => '校验amt',
                          CHECK_QUERY_IN   => 'select amt from demo_invest_pop_result_tmp where YAPPL_NUM = ' ||
                                              yappl_num,
                          AGAINST_VALUE_IN => expected_amt);
  end assert_detail_by_appl;

  procedure create_one_term_acct_for_emp(appl_num     in demo_appl_num_rel.appl_num%type,
                                       invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                       amt          in demo_appl_num_rel.AMT%type) is
  begin
    create_one_appl_num_rel(appl_num, invest_time, amt);
  
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

  procedure create_one_appl_num_rel(appl_num     in demo_appl_num_rel.appl_num%type,
                                    invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                    amt          in demo_appl_num_rel.AMT%type) is
  begin
    insert into demo_appl_num_rel
      (CO_ID, INVEST_ID, APPL_NUM, INVEST_TIME, AMT, RED_AMT)
    values
      (co_id, invest_id, appl_num, invest_time, amt, 0.00);
  end;

  procedure create_one_term_acct_for_co(appl_num     in demo_appl_num_rel.appl_num%type,
                                        invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                        amt          in demo_appl_num_rel.AMT%type) is
  begin
    create_one_appl_num_rel(appl_num, invest_time, amt);
  
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

  procedure create_mult_term_for_unit_val is
  begin
    UT_PKG_DEMO_COMMON.create_one_item_for_unit_value(term_one_invest_time, eval_state_flag_traded);
    UT_PKG_DEMO_COMMON.create_one_item_for_unit_value(term_two_invest_time, eval_state_flag_recent_traded);
    UT_PKG_DEMO_COMMON.create_one_item_for_unit_value(red_term_invest_time, eval_state_flag_not_excuted);
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
