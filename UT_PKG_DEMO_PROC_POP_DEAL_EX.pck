CREATE OR REPLACE PACKAGE UT_PKG_DEMO_PROC_POP_DEAL_EX IS
  PROCEDURE UT_SETUP;
  PROCEDURE UT_TEARDOWN;

  PROCEDURE UT_EX_EMP_ONE_TERM_ONE_APPL;
  PROCEDURE UT_EX_EMP_MULT_TERM_ONE_APPL;
  PROCEDURE UT_EX_EMP_MULT_TERM_MULT_APPL;
  PROCEDURE UT_EX_EMP_MULT_TERM_NOTENOUGH;
  PROCEDURE UT_EX_EMP_MAX_FIVE_APPL;
  PROCEDURE UT_EX_MULT_EMP_ONE_APPL;
  PROCEDURE UT_EX_MULT_EMP_MULT_TERM;
  PROCEDURE UT_EX_CO_ONE_TERM_ONE_APPL;
  PROCEDURE UT_EX_CO_MULT_TERM_ONE_APPL;
  PROCEDURE UT_EX_CO_MULT_TERM_MULT_APPL;
  PROCEDURE UT_EX_CO_MULT_TERM_NOTENOUGH;
  PROCEDURE UT_EX_CO_MAX_FIVE_APPL;
  PROCEDURE UT_EX_GET_NEXT_RED_TIME_NULL;

  procedure create_one_term_acct_for_emp(emp_id       in demo_emp_info.emp_id%type,
                                         appl_num     in demo_appl_num_rel.appl_num%type,
                                         invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                         amt          in demo_appl_num_rel.AMT%type);
  procedure create_one_term_acct_for_co(appl_num     in demo_appl_num_rel.appl_num%type,
                                        invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                        amt          in demo_appl_num_rel.AMT%type);
  procedure create_one_appl_num_rel(appl_num     in demo_appl_num_rel.appl_num%type,
                                    invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                    amt          in demo_appl_num_rel.AMT%type);

  procedure assert_detail_by_appl(emp_id      in demo_emp_info.emp_id%type,
                                  yappl_num   in number,
                                  expected_invest_time in varchar2,
                                  expected_amt         in number);

  invest_id                         constant DEMO_INVEST_INFO.INVEST_ID%type := UT_PKG_DEMO_COMMON.invest_id;
  co_id                             constant demo_co_invest.co_id%type := UT_PKG_DEMO_COMMON.co_id;
  emp_id                            constant demo_emp_invest.emp_id%type := UT_PKG_DEMO_COMMON.emp_id;
  emp_id_for_co                     constant demo_emp_invest.emp_id%type := UT_PKG_DEMO_COMMON.emp_id_for_co;
  subject_type_emp                  constant demo_emp_invest.subject_type%type := UT_PKG_DEMO_COMMON.subject_type_emp;
  subject_type_co                   constant demo_emp_invest.subject_type%type := UT_PKG_DEMO_COMMON.subject_type_co;

  term_one_invest_time              constant VARCHAR2(10) := UT_PKG_DEMO_COMMON.term_one_invest_time;
  term_two_invest_time              constant VARCHAR2(10) := UT_PKG_DEMO_COMMON.term_two_invest_time;
  red_term_invest_time              constant VARCHAR2(10) := UT_PKG_DEMO_COMMON.red_term_invest_time;

  appl_num_one                      constant demo_appl_num_rel.appl_num%type := 1;
  appl_num_two                      constant demo_appl_num_rel.appl_num%type := 2;
  appl_num_three                    constant demo_appl_num_rel.appl_num%type := 3;
  appl_num_four                     constant demo_appl_num_rel.appl_num%type := 4;
  appl_num_five                     constant demo_appl_num_rel.appl_num%type := 5;
  appl_num_six                      constant demo_appl_num_rel.appl_num%type := 6;

  default_amount                    constant number(17, 2) := 100;
  one_term_one_appl_red_amt         constant demo_invest_pop_tmp.amt%type := 90;
  mult_term_mult_appl_red_amt       constant demo_invest_pop_tmp.amt%type := 250;

  op_control_purchase_term_no       number;
  OUT_FLAG                          number;
  OUT_MSG                           VARCHAR2(2000);
END UT_PKG_DEMO_PROC_POP_DEAL_EX;
/
CREATE OR REPLACE PACKAGE BODY UT_PKG_DEMO_PROC_POP_DEAL_EX IS
  PROCEDURE create_invest_info is
  begin
    insert into demo_invest_info
      (PLAN_ID, INVEST_ID, INVEST_NAME)
    values
      (UT_PKG_DEMO_COMMON.plan_id, invest_id, '组合名称');
  end;

  PROCEDURE UT_SETUP IS
  BEGIN
    PKG_DEMO_COMMON.ret_of_func_is_expert_lcr := UT_PKG_DEMO_COMMON.True;

    create_invest_info;

    OUT_FLAG := -1;
    op_control_purchase_term_no := 1;

    UT_PKG_DEMO_COMMON.create_one_purchase_for_op_ctl(term_one_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_one_purchase_for_op_ctl(term_two_invest_time, op_control_purchase_term_no);
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
    UT_PKG_DEMO_COMMON.create_red_pur_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_one_term_for_unit_val;
    create_one_term_acct_for_emp(emp_id,appl_num_one, term_one_invest_time, one_term_one_appl_red_amt);

    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id, subject_type_emp, one_term_one_appl_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => invest_id,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    UT_PKG_DEMO_COMMON.assert_return_success(out_flag);
    UT_PKG_DEMO_COMMON.assert_redemption_obj(subject_type_emp, emp_id);
    UT_PKG_DEMO_COMMON.assert_result_count(1);
    assert_detail_by_appl(emp_id, appl_num_one, term_one_invest_time, one_term_one_appl_red_amt);
  END;

  /*
  涉及一期，且一期只有一张申请单，一期资产够（个人）
  */
  PROCEDURE UT_EX_EMP_MULT_TERM_ONE_APPL IS
    mult_term_one_appl_red_amt        constant demo_invest_pop_tmp.amt%type := 180;
  BEGIN
    UT_PKG_DEMO_COMMON.create_red_pur_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_mult_term_for_unit_val;
    create_one_term_acct_for_emp(emp_id, appl_num_one, term_one_invest_time, default_amount);
    create_one_term_acct_for_emp(emp_id, appl_num_two, term_two_invest_time, default_amount);

    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id, subject_type_emp, mult_term_one_appl_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    UT_PKG_DEMO_COMMON.assert_return_success(out_flag);
    UT_PKG_DEMO_COMMON.assert_redemption_obj(subject_type_emp, emp_id);
    UT_PKG_DEMO_COMMON.assert_result_count(2);
    assert_detail_by_appl(emp_id, appl_num_one, term_one_invest_time, mult_term_one_appl_red_amt - default_amount);
    assert_detail_by_appl(emp_id, appl_num_two, term_two_invest_time, default_amount);
  END;

  /*
  涉及多期，且多期只有多张申请单，多期资产够（个人）
  */
  PROCEDURE UT_EX_EMP_MULT_TERM_MULT_APPL IS
  BEGIN
    UT_PKG_DEMO_COMMON.create_red_pur_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_mult_term_for_unit_val;
    create_one_term_acct_for_emp(emp_id, appl_num_one, term_one_invest_time, default_amount);
    create_one_term_acct_for_emp(emp_id, appl_num_two, term_two_invest_time, default_amount);
    create_one_term_acct_for_emp(emp_id, appl_num_three, term_one_invest_time, default_amount);

    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id, subject_type_emp, mult_term_mult_appl_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    UT_PKG_DEMO_COMMON.assert_return_success(out_flag);
    UT_PKG_DEMO_COMMON.assert_redemption_obj(subject_type_emp, emp_id);
    UT_PKG_DEMO_COMMON.assert_result_count(3);
    assert_detail_by_appl(emp_id, appl_num_one, term_one_invest_time, mult_term_mult_appl_red_amt - default_amount * 2);
    assert_detail_by_appl(emp_id, appl_num_two, term_two_invest_time, default_amount);
    assert_detail_by_appl(emp_id, appl_num_three, term_one_invest_time, default_amount);
  END;

  /*
  涉及多期，且多期只有多张申请单，多期资产够（个人）
  */
  PROCEDURE UT_EX_EMP_MULT_TERM_NOTENOUGH IS
    not_enough_red_amt                constant demo_invest_pop_tmp.amt%type := 310;
  BEGIN
    UT_PKG_DEMO_COMMON.create_red_pur_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_mult_term_for_unit_val;
    create_one_term_acct_for_emp(emp_id, appl_num_one, term_one_invest_time, default_amount);
    create_one_term_acct_for_emp(emp_id, appl_num_two, term_two_invest_time, default_amount);
    create_one_term_acct_for_emp(emp_id, appl_num_three, term_one_invest_time, default_amount);

    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id, subject_type_emp, not_enough_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    UT_PKG_DEMO_COMMON.assert_out_flag(out_flag, 2);
  END;
  
    /*
  赎回涉及超过五张申请单（企业）
  */
  PROCEDURE UT_EX_EMP_MAX_FIVE_APPL IS
    enough_red_amt_for_over_five      constant demo_invest_pop_tmp.amt%type := 580;
  BEGIN
    UT_PKG_DEMO_COMMON.create_red_pur_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_mult_term_for_unit_val;
    create_one_term_acct_for_emp(emp_id, appl_num_one, term_one_invest_time, default_amount);
    create_one_term_acct_for_emp(emp_id, appl_num_two, term_two_invest_time, default_amount);
    create_one_term_acct_for_emp(emp_id, appl_num_three, term_one_invest_time, default_amount);
    create_one_term_acct_for_emp(emp_id, appl_num_four, term_one_invest_time, default_amount);
    create_one_term_acct_for_emp(emp_id, appl_num_five, term_one_invest_time, default_amount);
    create_one_term_acct_for_emp(emp_id, appl_num_six, term_one_invest_time, default_amount);

    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id, subject_type_emp, enough_red_amt_for_over_five);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    UT_PKG_DEMO_COMMON.assert_out_flag(out_flag, 3);
    UT_PKG_DEMO_COMMON.assert_result_count(6);
    assert_detail_by_appl(emp_id, appl_num_one, term_one_invest_time, enough_red_amt_for_over_five - default_amount * 5);
    assert_detail_by_appl(emp_id, appl_num_two, term_two_invest_time, default_amount);
    assert_detail_by_appl(emp_id, appl_num_three, term_one_invest_time, default_amount);
    assert_detail_by_appl(emp_id, appl_num_four, term_one_invest_time, default_amount);
    assert_detail_by_appl(emp_id, appl_num_five, term_one_invest_time, default_amount);
    assert_detail_by_appl(emp_id, appl_num_six, term_one_invest_time, default_amount);
  END;
  
  PROCEDURE UT_EX_MULT_EMP_ONE_APPL IS
    ANOTHER_EMP_ID CONSTANT DEMO_EMP_INFO.EMP_ID%TYPE := '0000000002';
  BEGIN
    UT_PKG_DEMO_COMMON.create_red_pur_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_one_term_for_unit_val;
    create_one_term_acct_for_emp(emp_id, appl_num_one, term_one_invest_time, one_term_one_appl_red_amt);
    create_one_term_acct_for_emp(ANOTHER_EMP_ID, appl_num_one, term_one_invest_time, one_term_one_appl_red_amt);

    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id, subject_type_emp, one_term_one_appl_red_amt);
    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(ANOTHER_EMP_ID, subject_type_emp, one_term_one_appl_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => invest_id,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    UT_PKG_DEMO_COMMON.assert_return_success(out_flag);
    UT_PKG_DEMO_COMMON.assert_redemption_obj(subject_type_emp, emp_id);
    UT_PKG_DEMO_COMMON.assert_redemption_obj(subject_type_emp, ANOTHER_EMP_ID);
    UT_PKG_DEMO_COMMON.assert_result_count(2);
    assert_detail_by_appl(emp_id, appl_num_one, term_one_invest_time, one_term_one_appl_red_amt);
    assert_detail_by_appl(ANOTHER_EMP_ID, appl_num_one, term_one_invest_time, one_term_one_appl_red_amt);
  END;
  
  PROCEDURE UT_EX_MULT_EMP_MULT_TERM IS
    ANOTHER_EMP_ID CONSTANT DEMO_EMP_INFO.EMP_ID%TYPE := '0000000002';
  BEGIN
    UT_PKG_DEMO_COMMON.create_red_pur_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_mult_term_for_unit_val;
    create_one_term_acct_for_emp(emp_id, appl_num_one, term_one_invest_time, one_term_one_appl_red_amt);
    create_one_term_acct_for_emp(ANOTHER_EMP_ID, appl_num_one, term_one_invest_time, one_term_one_appl_red_amt);
    create_one_term_acct_for_emp(emp_id, appl_num_two, term_two_invest_time, one_term_one_appl_red_amt);
    create_one_term_acct_for_emp(ANOTHER_EMP_ID, appl_num_two, term_two_invest_time, one_term_one_appl_red_amt);
    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id, subject_type_emp, one_term_one_appl_red_amt*2);
    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(ANOTHER_EMP_ID, subject_type_emp, one_term_one_appl_red_amt*2);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => invest_id,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    UT_PKG_DEMO_COMMON.assert_return_success(out_flag);
    UT_PKG_DEMO_COMMON.assert_redemption_obj(subject_type_emp, emp_id);
    UT_PKG_DEMO_COMMON.assert_result_count(4);
    assert_detail_by_appl(emp_id, appl_num_one, term_one_invest_time, one_term_one_appl_red_amt);
    assert_detail_by_appl(emp_id, appl_num_two, term_two_invest_time, one_term_one_appl_red_amt);
    assert_detail_by_appl(ANOTHER_EMP_ID, appl_num_one, term_one_invest_time, one_term_one_appl_red_amt);
    assert_detail_by_appl(ANOTHER_EMP_ID, appl_num_two, term_two_invest_time, one_term_one_appl_red_amt);
  END;
  
    /*
  涉及一期，且一期只有一张申请单，一期资产够（个人）
  */
  PROCEDURE UT_EX_CO_ONE_TERM_ONE_APPL IS
  BEGIN
    UT_PKG_DEMO_COMMON.create_red_pur_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_one_term_for_unit_val;
    create_one_term_acct_for_co(appl_num_one, term_one_invest_time, one_term_one_appl_red_amt);

    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id_for_co, subject_type_co, one_term_one_appl_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => invest_id,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    UT_PKG_DEMO_COMMON.assert_return_success(out_flag);
    UT_PKG_DEMO_COMMON.assert_redemption_obj(subject_type_co, emp_id_for_co);
    UT_PKG_DEMO_COMMON.assert_result_count(1);
    assert_detail_by_appl(emp_id_for_co, appl_num_one, term_one_invest_time, one_term_one_appl_red_amt);
  END;

  /*
  涉及一期，且一期只有一张申请单，一期资产够（个人）
  */
  PROCEDURE UT_EX_CO_MULT_TERM_ONE_APPL IS
    mult_term_one_appl_red_amt        constant demo_invest_pop_tmp.amt%type := 180;
  BEGIN
    UT_PKG_DEMO_COMMON.create_red_pur_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_mult_term_for_unit_val;
    create_one_term_acct_for_co(appl_num_one, term_one_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_two, term_two_invest_time, default_amount);

    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id_for_co, subject_type_co, mult_term_one_appl_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    UT_PKG_DEMO_COMMON.assert_return_success(out_flag);
    UT_PKG_DEMO_COMMON.assert_redemption_obj(subject_type_co, emp_id_for_co);
    UT_PKG_DEMO_COMMON.assert_result_count(2);
    assert_detail_by_appl(emp_id_for_co, appl_num_one, term_one_invest_time, mult_term_one_appl_red_amt - default_amount);
    assert_detail_by_appl(emp_id_for_co, appl_num_two, term_two_invest_time, default_amount);
  END;

  /*
  涉及多期，且多期只有多张申请单，多期资产够（企业）
  */
  PROCEDURE UT_EX_CO_MULT_TERM_MULT_APPL IS
  BEGIN
    UT_PKG_DEMO_COMMON.create_red_pur_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_mult_term_for_unit_val;
    create_one_term_acct_for_co(appl_num_one, term_one_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_two, term_two_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_three, term_one_invest_time, default_amount);

    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id_for_co, subject_type_co, mult_term_mult_appl_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    UT_PKG_DEMO_COMMON.assert_return_success(out_flag);
    UT_PKG_DEMO_COMMON.assert_redemption_obj(subject_type_co, emp_id_for_co);
    UT_PKG_DEMO_COMMON.assert_result_count(3);
    assert_detail_by_appl(emp_id_for_co, appl_num_one, term_one_invest_time, mult_term_mult_appl_red_amt - default_amount * 2);
    assert_detail_by_appl(emp_id_for_co, appl_num_two, term_two_invest_time, default_amount);
    assert_detail_by_appl(emp_id_for_co, appl_num_three, term_one_invest_time, default_amount);
  END;
  
  /*
  涉及多期，且多期只有多张申请单，多期资产够（个人）
  */
  PROCEDURE UT_EX_CO_MULT_TERM_NOTENOUGH IS
    not_enough_red_amt                constant demo_invest_pop_tmp.amt%type := 310;
  BEGIN
    UT_PKG_DEMO_COMMON.create_red_pur_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_mult_term_for_unit_val;
    create_one_term_acct_for_co(appl_num_one, term_one_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_two, term_two_invest_time, default_amount);
    create_one_term_acct_for_co(appl_num_three, term_one_invest_time, default_amount);

    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id_for_co, subject_type_co, not_enough_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    UT_PKG_DEMO_COMMON.assert_out_flag(out_flag, 2);
  END;

  /*
  赎回涉及超过五张申请单（企业）
  */
  PROCEDURE UT_EX_CO_MAX_FIVE_APPL IS
    enough_red_amt_for_over_five      constant demo_invest_pop_tmp.amt%type := 580;
  BEGIN
    UT_PKG_DEMO_COMMON.create_red_pur_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_mult_term_for_unit_val;
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

    UT_PKG_DEMO_COMMON.assert_out_flag(out_flag, 3);
    UT_PKG_DEMO_COMMON.assert_result_count(6);
    assert_detail_by_appl(emp_id_for_co, appl_num_one, term_one_invest_time, enough_red_amt_for_over_five - default_amount * 5);
    assert_detail_by_appl(emp_id_for_co, appl_num_two, term_two_invest_time, default_amount);
    assert_detail_by_appl(emp_id_for_co, appl_num_three, term_one_invest_time, default_amount);
    assert_detail_by_appl(emp_id_for_co, appl_num_four, term_one_invest_time, default_amount);
    assert_detail_by_appl(emp_id_for_co, appl_num_five, term_one_invest_time, default_amount);
    assert_detail_by_appl(emp_id_for_co, appl_num_six, term_one_invest_time, default_amount);
  END;
  
  
  procedure UT_EX_GET_NEXT_RED_TIME_NULL IS
    
  BEGIN
    UT_PKG_DEMO_COMMON.create_one_term_for_unit_val;
    create_one_term_acct_for_emp(emp_id, appl_num_one, term_one_invest_time, one_term_one_appl_red_amt);

    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id, subject_type_emp, one_term_one_appl_red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => invest_id,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
    UT_PKG_DEMO_COMMON.assert_out_flag(out_flag, 2);
  END;
  
  procedure assert_detail_by_appl(emp_id      in demo_emp_info.emp_id%type,
                                  yappl_num   in number,
                                  expected_invest_time in varchar2,
                                  expected_amt         in number) is
  begin
    utassert.eqqueryvalue(msg_in           => '校验invest_time',
                          CHECK_QUERY_IN   => 'select invest_time from demo_invest_pop_result_tmp where YAPPL_NUM = ' ||
                                              yappl_num || ' and emp_id = ''' || emp_id || '''',
                          AGAINST_VALUE_IN => expected_invest_time);

    utassert.eqqueryvalue(msg_in           => '校验quotient',
                          CHECK_QUERY_IN   => 'select quotient from demo_invest_pop_result_tmp where YAPPL_NUM = ' ||
                                              yappl_num || ' and emp_id = ''' || emp_id || '''',
                          AGAINST_VALUE_IN => expected_amt);

    utassert.eqqueryvalue(msg_in           => '校验amt',
                          CHECK_QUERY_IN   => 'select amt from demo_invest_pop_result_tmp where YAPPL_NUM = ' ||
                                              yappl_num || ' and emp_id = ''' || emp_id || '''',
                          AGAINST_VALUE_IN => expected_amt);
  end assert_detail_by_appl;
  
  procedure create_one_term_acct_for_emp(emp_id       in demo_emp_info.emp_id%type,
                                         appl_num     in demo_appl_num_rel.appl_num%type,
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
    merge into demo_appl_num_rel a
    using (select co_id co_id, invest_id invest_id, appl_num appl_num, invest_time invest_time, amt amt, 0.00 red_amt
             from dual) b
    on (a.appl_num = b.appl_num)
    when matched then
      update set a.amt = a.amt + b.amt
    when not matched then
      insert
        (CO_ID, INVEST_ID, APPL_NUM, INVEST_TIME, AMT, RED_AMT)
      values
        (b.co_id, b.invest_id, b.appl_num, b.invest_time, b.amt, b.red_amt);
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

END UT_PKG_DEMO_PROC_POP_DEAL_EX;
/

set serveroutput on
/

exec utplsql.run ('UT_PKG_DEMO_PROC_POP_DEAL_EX', per_method_setup_in => TRUE)
/

select last_status from ut_package where name = 'UT_PKG_DEMO_PROC_POP_DEAL_EX';
