CREATE OR REPLACE PACKAGE UT_PKG_DEMO_PROC_POP_DEAL_UNEX IS
  PROCEDURE UT_SETUP;
  PROCEDURE UT_TEARDOWN;

  PROCEDURE UT_UNEX_EMP_ENOUGH;
  PROCEDURE UT_UNEX_CO_ENOUGH;
  PROCEDURE UT_UNEX_CO_NOTENOUGH;
  PROCEDURE UT_UNEX_NOT_EXIST_DONE_OP_DATE;

  procedure create_unex_prod_info;
  procedure create_emp_invest_info(original_amt demo_emp_invest.QUOTIENT%type,
                                   original_quotient demo_emp_invest.AMT%type);
  procedure create_co_invest_info(original_amt demo_emp_invest.QUOTIENT%type,
                                  original_quotient demo_emp_invest.AMT%type);

  procedure assert_quotient_and_amt(expected_red_quotient demo_invest_pop_result_tmp.QUOTIENT%type,
                                    expected_amt demo_invest_pop_result_tmp.AMT%type);

  invest_id                         constant DEMO_INVEST_INFO.INVEST_ID%type := UT_PKG_DEMO_COMMON.invest_id;
  co_id                             constant demo_co_invest.co_id%type := UT_PKG_DEMO_COMMON.co_id;
  emp_id                            constant demo_emp_invest.emp_id%type := UT_PKG_DEMO_COMMON.emp_id;
  emp_id_for_co                     constant demo_emp_invest.emp_id%type := UT_PKG_DEMO_COMMON.emp_id_for_co;
  subject_type_emp                  constant demo_emp_invest.subject_type%type := UT_PKG_DEMO_COMMON.subject_type_emp;
  subject_type_co                   constant demo_emp_invest.subject_type%type := UT_PKG_DEMO_COMMON.subject_type_co;

  term_one_invest_time              constant VARCHAR2(10) := UT_PKG_DEMO_COMMON.term_one_invest_time;
  red_term_invest_time              constant VARCHAR2(10) := UT_PKG_DEMO_COMMON.red_term_invest_time;

  enough_red_quotient               demo_invest_pop_tmp.amt%type := 40;
  not_enough_red_quotient           demo_invest_pop_tmp.amt%type := 100;
  original_quotient                 demo_emp_invest.QUOTIENT%type := 50;
  original_amt                      demo_emp_invest.AMT%type := 100;

  op_control_purchase_term_no       number;
  OUT_FLAG                          number;
  OUT_MSG                           VARCHAR2(2000);
END UT_PKG_DEMO_PROC_POP_DEAL_UNEX;
/
CREATE OR REPLACE PACKAGE BODY UT_PKG_DEMO_PROC_POP_DEAL_UNEX IS
  PROCEDURE UT_SETUP IS
  BEGIN
    OUT_FLAG := -1;
    op_control_purchase_term_no := 1;

    UT_PKG_DEMO_COMMON.create_plan_info;
    create_unex_prod_info;
    UT_PKG_DEMO_COMMON.create_one_purchase_for_op_ctl(term_one_invest_time, op_control_purchase_term_no);
    UT_PKG_DEMO_COMMON.create_red_pur_for_op_ctl(red_term_invest_time, op_control_purchase_term_no);
    
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
    UT_PKG_DEMO_COMMON.create_one_term_for_unit_val;
    create_emp_invest_info(original_amt, original_quotient);

    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id, subject_type_emp, enough_red_quotient);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    UT_PKG_DEMO_COMMON.assert_return_success(out_flag);
    UT_PKG_DEMO_COMMON.assert_redemption_obj(subject_type_emp, emp_id);
    UT_PKG_DEMO_COMMON.assert_result_count(1);
    assert_quotient_and_amt(enough_red_quotient, enough_red_quotient / original_quotient * original_amt);
  END;

  /*
  净值报价型，企业赎回
  */
  PROCEDURE UT_UNEX_CO_ENOUGH IS
  BEGIN
    UT_PKG_DEMO_COMMON.create_one_term_for_unit_val;
    create_co_invest_info(original_amt, original_quotient);

    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id_for_co, subject_type_co, enough_red_quotient);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    UT_PKG_DEMO_COMMON.assert_return_success(out_flag);
    UT_PKG_DEMO_COMMON.assert_redemption_obj(subject_type_co, emp_id_for_co);
    UT_PKG_DEMO_COMMON.assert_result_count(1);
    assert_quotient_and_amt(enough_red_quotient, enough_red_quotient / original_quotient * original_amt);
  END;

  /*
  净值报价型，企业赎回,不够
  */
  PROCEDURE UT_UNEX_CO_NOTENOUGH IS
  BEGIN
    UT_PKG_DEMO_COMMON.create_one_term_for_unit_val;
    create_co_invest_info(original_amt, original_quotient);

    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id_for_co, subject_type_co, not_enough_red_quotient);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    UT_PKG_DEMO_COMMON.assert_out_flag(out_flag, 2);
  END;
  
  /*净值报价型产品，不存在已完成的集中确认日*/
  PROCEDURE UT_UNEX_NOT_EXIST_DONE_OP_DATE IS
  BEGIN
    UT_PKG_DEMO_COMMON.create_one_item_for_unit_value(UT_PKG_DEMO_COMMON.term_one_invest_time, UT_PKG_DEMO_COMMON.eval_state_flag_not_excuted);
    create_co_invest_info(original_amt, original_quotient);

    UT_PKG_DEMO_COMMON.create_invest_pop_parameters(emp_id_for_co, subject_type_co, enough_red_quotient);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);

    UT_PKG_DEMO_COMMON.assert_out_flag(out_flag, 2);
  END;

  procedure create_unex_prod_info is
  begin
    UT_PKG_DEMO_COMMON.create_prod_info(UT_PKG_DEMO_COMMON.False);
  end create_unex_prod_info;

  procedure create_emp_invest_info(original_amt demo_emp_invest.QUOTIENT%type,
                                   original_quotient demo_emp_invest.AMT%type) is
  begin
    insert into demo_emp_invest
      (EMP_ID, CO_ID, SUBJECT_TYPE, INVEST_ID, AMT, QUOTIENT, SET_VALUE)
    values
      (emp_id, co_id, subject_type_emp, INVEST_ID, original_amt, original_quotient, UT_PKG_DEMO_COMMON.Dummy);
  end;

  procedure create_co_invest_info(original_amt demo_emp_invest.QUOTIENT%type,
                                  original_quotient demo_emp_invest.AMT%type) is
  begin
    insert into demo_co_invest
      (CO_ID, SUBJECT_TYPE, INVEST_ID, AMT, QUOTIENT, SET_VALUE)
    values
      (co_id, subject_type_co, INVEST_ID, original_amt, original_quotient, UT_PKG_DEMO_COMMON.Dummy);
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

END UT_PKG_DEMO_PROC_POP_DEAL_UNEX;
/
