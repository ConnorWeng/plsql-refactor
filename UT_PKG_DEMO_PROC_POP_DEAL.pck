CREATE OR REPLACE PACKAGE UT_PKG_DEMO_PROC_POP_DEAL IS
  PROCEDURE UT_SETUP;
  PROCEDURE UT_TEARDOWN;

  PROCEDURE UT_EX_EMP_ONE_TERM_ONE_APPL;
  PROCEDURE UT_EX_EMP_MULT_TERM_ONE_APPL;
  PROCEDURE UT_EX_EMP_MULT_TERM_MULT_APPL;
  PROCEDURE UT_EX_EMP_MULT_TERM_NOTENOUGH;
  PROCEDURE UT_EX_CO_MULT_TERM;
  PROCEDURE UT_EX_CO_MAX_FIVE_APPL;
  PROCEDURE UT_UNEX_EMP_ENOUGH;
  PROCEDURE UT_UNEX_CO_ENOUGH;
  PROCEDURE UT_UNEX_CO_NOTENOUGH;

  procedure create_plan_info(plan_id in demo_plan_info.plan_id%type);
  procedure create_ex_prod_info(invest_id in DEMO_INVEST_INFO.INVEST_ID%type,
                                plan_id   in demo_plan_info.plan_id%type);
  procedure create_unex_prod_info(invest_id in DEMO_INVEST_INFO.INVEST_ID%type,
                                  plan_id   in demo_plan_info.plan_id%type);
  procedure create_prod_info(invest_id in DEMO_INVEST_INFO.INVEST_ID%type,
                             plan_id   in demo_plan_info.plan_id%type,
                             buy_way in demo_invest_basic_info.BUY_WAY%type);
  procedure create_one_term_acct_for_emp(invest_id in DEMO_INVEST_INFO.INVEST_ID%type,
                                         subject_type in demo_emp_invest.subject_type%type,
                                         co_id        in demo_co_invest.co_id%type,
                                         emp_id       in demo_emp_invest.emp_id%type,
                                         appl_num     in demo_appl_num_rel.appl_num%type,
                                         invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                         amt          in demo_appl_num_rel.AMT%type);
  procedure create_one_term_acct_for_co(invest_id in DEMO_INVEST_INFO.INVEST_ID%type,
                                        subject_type in demo_emp_invest.subject_type%type,
                                        co_id        in demo_co_invest.co_id%type,
                                        appl_num     in demo_appl_num_rel.appl_num%type,
                                        invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                        amt          in demo_appl_num_rel.AMT%type);
  function one_day_before(day VARCHAR2) return VARCHAR2;
  procedure create_invest_pop_parameters(emp_id demo_emp_invest.emp_id%type,
                                         co_id demo_co_invest.co_id%type,
                                         subject_type demo_emp_invest.subject_type%type,
                                         red_amt demo_invest_pop_tmp.amt%type);
  
  procedure assert_redemption_obj(expected_subject_type in demo_emp_invest.subject_type%type,
                                  expected_co_id        in demo_co_invest.co_id%type,
                                  expected_emp_id       in demo_emp_invest.emp_id%type);
  procedure assert_return_success(expected_out_flag in number,
                                  expected_out_msg in VARCHAR2);
  procedure assert_detail_by_appl(yappl_num   in number,
                                  expected_invest_time in varchar2,
                                  expected_quotient    in number,
                                  expected_amt         in number);
END UT_PKG_DEMO_PROC_POP_DEAL;
/

CREATE OR REPLACE PACKAGE BODY UT_PKG_DEMO_PROC_POP_DEAL IS
  PROCEDURE UT_SETUP IS
  BEGIN
    null;
  END;
  PROCEDURE UT_TEARDOWN IS
  BEGIN
    rollback;
  END;
  
  /*
  涉及一期，且一期只有一张申请单，一期资产够（个人）
  */
  PROCEDURE UT_EX_EMP_ONE_TERM_ONE_APPL IS
    OUT_FLAG               number;
    OUT_MSG                VARCHAR2(2000);
    invest_id            DEMO_INVEST_INFO.INVEST_ID%type := '990001';
    plan_id              demo_plan_info.plan_id%type := '000001';
    subject_type         demo_emp_invest.subject_type%type := '301001';
    co_id                demo_co_invest.co_id%type := '0000001000000';
    emp_id               demo_emp_invest.emp_id%type := '0000000001';
    term_one_invest_time VARCHAR2(10) := '2013-01-01';
    red_term_invest_time VARCHAR2(10) := '2013-12-16';
    red_amt              demo_invest_pop_tmp.amt%type := 90;
    
  
  BEGIN
    create_plan_info(plan_id);
    create_ex_prod_info(invest_id, plan_id);
    create_one_term_acct_for_emp(invest_id,
                               subject_type,
                               co_id,
                               emp_id,
                               1,
                               term_one_invest_time,
                               100);
  
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (invest_id, 2, 1, term_one_invest_time);
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (invest_id, 3, 1, one_day_before(red_term_invest_time));
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (invest_id, 2, 2, red_term_invest_time);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (invest_id, term_one_invest_time, plan_id, 1, 2);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (invest_id, red_term_invest_time, plan_id, 1, 3);
   
    create_invest_pop_parameters(emp_id, co_id, subject_type, red_amt);
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => invest_id,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
  
    assert_return_success(OUT_FLAG, OUT_MSG);
    assert_redemption_obj(subject_type, co_id, emp_id);
  
    --校验tablecount
    utassert.eqqueryvalue(msg_in           => 'check tablecount',
                          CHECK_QUERY_IN   => 'select count(1) from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => 1);
  
    --根据申请单号校验数据
    assert_detail_by_appl(1, term_one_invest_time, 90, 90);
  
  END;

  procedure create_invest_pop_parameters(emp_id demo_emp_invest.emp_id%type,
                                         co_id demo_co_invest.co_id%type,
                                         subject_type demo_emp_invest.subject_type%type,
                                         red_amt demo_invest_pop_tmp.amt%type) is
  begin
    insert into demo_invest_pop_tmp
      (EMP_ID, CO_ID, SUBJECT_TYPE, AMT)
    values
      (emp_id, co_id, subject_type, red_amt);
  end;

  /*
  涉及一期，且一期只有一张申请单，一期资产够（个人）
  */
  PROCEDURE UT_EX_EMP_MULT_TERM_ONE_APPL IS
    --out arguements definition
    OUT_FLAG               number;
    OUT_MSG                VARCHAR2(2000);
    V_INVEST_ID            DEMO_INVEST_INFO.INVEST_ID%type := '990001';
    v_plan_id              demo_plan_info.plan_id%type := '000001';
    v_subject_type         demo_emp_invest.subject_type%type := '301001';
    v_co_id                demo_co_invest.co_id%type := '0000001000000';
    v_emp_id               demo_emp_invest.emp_id%type := '0000000001';
    v_term_one_invest_time VARCHAR2(10) := '2013-01-01';
    v_term_two_invest_time VARCHAR2(10) := '2013-02-01';
    v_red_term_invest_time VARCHAR2(10) := '2013-12-16';
    v_red_amt              demo_invest_pop_tmp.amt%type := 180;
  BEGIN
    --准备数据
    --计划数据
    create_plan_info(v_plan_id);
    --账务数据
    create_one_term_acct_for_emp(V_INVEST_ID,
                               v_subject_type,
                               v_co_id,
                               v_emp_id,
                               1,
                               v_term_one_invest_time,
                               100);
    create_one_term_acct_for_emp(V_INVEST_ID,
                               v_subject_type,
                               v_co_id,
                               v_emp_id,
                               2,
                               v_term_two_invest_time,
                               100);
  
    --预期收益产品准备
    create_ex_prod_info(V_INVEST_ID, v_plan_id);
  
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 1, v_term_one_invest_time);
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 2, v_term_two_invest_time);
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id,
       3,
       1,
       to_char(to_date(v_red_term_invest_time, 'yyyy-mm-dd') - 1,
               'yyyy-mm-dd'));
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 3, v_red_term_invest_time);
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_term_one_invest_time, v_plan_id, 1, 1);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_term_two_invest_time, v_plan_id, 1, 2);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_red_term_invest_time, v_plan_id, 1, 3);
  
    --传入数据
    insert into demo_invest_pop_tmp
      (EMP_ID, CO_ID, SUBJECT_TYPE, AMT)
    values
      (v_emp_id, v_co_id, v_subject_type, v_red_amt);
  
    --执行被测代码
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => V_INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
  
    --执行asserts
    --校验返回信息
    assert_return_success(OUT_FLAG, OUT_MSG);
    --校验拆分对象
    assert_redemption_obj(v_subject_type, v_co_id, v_emp_id);
  
    --根据申请单号校验数据
    assert_detail_by_appl(1, v_term_one_invest_time, 80, 80);
    assert_detail_by_appl(2, v_term_two_invest_time, 100, 100);
  
  END;
  /*
  涉及多期，且多期只有多张申请单，多期资产够（个人）
  */
  PROCEDURE UT_EX_EMP_MULT_TERM_MULT_APPL IS
    --out arguements definition
    OUT_FLAG               number;
    OUT_MSG                VARCHAR2(2000);
    V_INVEST_ID            DEMO_INVEST_INFO.INVEST_ID%type := '990001';
    v_plan_id              demo_plan_info.plan_id%type := '000001';
    v_subject_type         demo_emp_invest.subject_type%type := '301001';
    v_co_id                demo_co_invest.co_id%type := '0000001000000';
    v_emp_id               demo_emp_invest.emp_id%type := '0000000001';
    v_term_one_invest_time VARCHAR2(10) := '2013-01-01';
    v_term_two_invest_time VARCHAR2(10) := '2013-02-01';
    v_red_term_invest_time VARCHAR2(10) := '2013-12-16';
    v_red_amt              demo_invest_pop_tmp.amt%type := 250;
  
  BEGIN
    --准备数据
    --计划数据
    create_plan_info(v_plan_id);
    --账务数据
    create_one_term_acct_for_emp(V_INVEST_ID,
                               v_subject_type,
                               v_co_id,
                               v_emp_id,
                               1,
                               v_term_one_invest_time,
                               100);
    create_one_term_acct_for_emp(V_INVEST_ID,
                               v_subject_type,
                               v_co_id,
                               v_emp_id,
                               2,
                               v_term_two_invest_time,
                               100);
    create_one_term_acct_for_emp(V_INVEST_ID,
                               v_subject_type,
                               v_co_id,
                               v_emp_id,
                               3,
                               v_term_one_invest_time,
                               100);
  
    --预期收益产品准备
    create_ex_prod_info(V_INVEST_ID, v_plan_id);
  
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 1, v_term_one_invest_time);
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 2, v_term_two_invest_time);
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id,
       3,
       1,
       to_char(to_date(v_red_term_invest_time, 'yyyy-mm-dd') - 1,
               'yyyy-mm-dd'));
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 12, v_red_term_invest_time);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_term_one_invest_time, v_plan_id, 1, 1);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_term_two_invest_time, v_plan_id, 1, 2);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_red_term_invest_time, v_plan_id, 1, 3);
  
    --传入数据
    insert into demo_invest_pop_tmp
      (EMP_ID, CO_ID, SUBJECT_TYPE, AMT)
    values
      (v_emp_id, v_co_id, v_subject_type, v_red_amt);
  
    --执行被测代码
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => V_INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
  
    --执行asserts
    --校验程序返回标志
    --校验返回信息
    assert_return_success(OUT_FLAG, OUT_MSG);
    --校验拆分对象
    assert_redemption_obj(v_subject_type, v_co_id, v_emp_id);
  
    --根据申请单号校验数据
    assert_detail_by_appl(1, v_term_one_invest_time, 100, 100);
    assert_detail_by_appl(3, v_term_one_invest_time, 50, 50);
    assert_detail_by_appl(2, v_term_two_invest_time, 100, 100);
  
  END;
  /*
  涉及多期，且多期只有多张申请单，多期资产够（个人）
  */
  PROCEDURE UT_EX_EMP_MULT_TERM_NOTENOUGH IS
    --out arguements definition
    OUT_FLAG               number;
    OUT_MSG                VARCHAR2(2000);
    V_INVEST_ID            DEMO_INVEST_INFO.INVEST_ID%type := '990001';
    v_plan_id              demo_plan_info.plan_id%type := '000001';
    v_subject_type         demo_emp_invest.subject_type%type := '301001';
    v_co_id                demo_co_invest.co_id%type := '0000001000000';
    v_emp_id               demo_emp_invest.emp_id%type := '0000000001';
    v_term_one_invest_time VARCHAR2(10) := '2013-01-01';
    v_term_two_invest_time VARCHAR2(10) := '2013-02-01';
    v_red_term_invest_time VARCHAR2(10) := '2013-12-16';
    v_red_amt              demo_invest_pop_tmp.amt%type := 310;
  
  BEGIN
    --准备数据
    --计划数据
    create_plan_info(v_plan_id);
    --账务数据
    create_one_term_acct_for_emp(V_INVEST_ID,
                               v_subject_type,
                               v_co_id,
                               v_emp_id,
                               1,
                               v_term_one_invest_time,
                               100);
    create_one_term_acct_for_emp(V_INVEST_ID,
                               v_subject_type,
                               v_co_id,
                               v_emp_id,
                               2,
                               v_term_two_invest_time,
                               100);
    create_one_term_acct_for_emp(V_INVEST_ID,
                               v_subject_type,
                               v_co_id,
                               v_emp_id,
                               3,
                               v_term_one_invest_time,
                               100);
  
    --预期收益产品准备
    create_ex_prod_info(V_INVEST_ID, v_plan_id);
  
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 1, v_term_one_invest_time);
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 2, v_term_two_invest_time);
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id,
       3,
       1,
       to_char(to_date(v_red_term_invest_time, 'yyyy-mm-dd') - 1,
               'yyyy-mm-dd'));
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 12, v_red_term_invest_time);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_term_one_invest_time, v_plan_id, 1, 1);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_term_two_invest_time, v_plan_id, 1, 2);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_red_term_invest_time, v_plan_id, 1, 3);
  
    --传入数据
    insert into demo_invest_pop_tmp
      (EMP_ID, CO_ID, SUBJECT_TYPE, AMT)
    values
      (v_emp_id, v_co_id, v_subject_type, v_red_amt);
  
    --执行被测代码
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => V_INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
    --执行asserts
    --校验程序返回标志
    utassert.eq(msg_in          => 'check OUT_FLAG',
                check_this_in   => OUT_FLAG,
                against_this_in => 2);
    --校验程序返回信息
    utassert.eq(msg_in          => 'check OUT_MSG',
                check_this_in   => OUT_MSG,
                against_this_in => '进行后进先出处理时，资产不足');
  
  END;
  /*
  涉及多期，且多期只有多张申请单，多期资产够（企业）
  */
  PROCEDURE UT_EX_CO_MULT_TERM IS
    --out arguements definition
    OUT_FLAG               number;
    OUT_MSG                VARCHAR2(2000);
    V_INVEST_ID            DEMO_INVEST_INFO.INVEST_ID%type := '990001';
    v_plan_id              demo_plan_info.plan_id%type := '000001';
    v_subject_type         demo_emp_invest.subject_type%type := '302101';
    v_co_id                demo_co_invest.co_id%type := '0000001000000';
    v_emp_id               demo_emp_invest.emp_id%type := 'FFFFFFFFFF';
    v_term_one_invest_time VARCHAR2(10) := '2013-01-01';
    v_term_two_invest_time VARCHAR2(10) := '2013-02-01';
    v_red_term_invest_time VARCHAR2(10) := '2013-12-16';
    v_red_amt              demo_invest_pop_tmp.amt%type := 250;
  
  BEGIN
    --准备数据
    --计划数据
    create_plan_info(v_plan_id);
    --账务数据
    create_one_term_acct_for_co(V_INVEST_ID,
                              v_subject_type,
                              v_co_id,
                              1,
                              v_term_one_invest_time,
                              100);
    create_one_term_acct_for_co(V_INVEST_ID,
                              v_subject_type,
                              v_co_id,
                              2,
                              v_term_two_invest_time,
                              100);
    create_one_term_acct_for_co(V_INVEST_ID,
                              v_subject_type,
                              v_co_id,
                              3,
                              v_term_one_invest_time,
                              100);
  
    --预期收益产品准备
    create_ex_prod_info(V_INVEST_ID, v_plan_id);
  
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 1, v_term_one_invest_time);
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 2, v_term_two_invest_time);
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id,
       3,
       1,
       to_char(to_date(v_red_term_invest_time, 'yyyy-mm-dd') - 1,
               'yyyy-mm-dd'));
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 12, v_red_term_invest_time);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_term_one_invest_time, v_plan_id, 1, 1);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_term_two_invest_time, v_plan_id, 1, 2);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_red_term_invest_time, v_plan_id, 1, 3);
  
    --传入数据
    insert into demo_invest_pop_tmp
      (EMP_ID, CO_ID, SUBJECT_TYPE, AMT)
    values
      (v_emp_id, v_co_id, v_subject_type, v_red_amt);
  
    --执行被测代码
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => V_INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
  
    --执行asserts
    --校验程序返回标志
    --校验返回信息
    assert_return_success(OUT_FLAG, OUT_MSG);
    --校验拆分对象
    assert_redemption_obj(v_subject_type, v_co_id, v_emp_id);
  
    --根据申请单号校验数据
    assert_detail_by_appl(1, v_term_one_invest_time, 100, 100);
    assert_detail_by_appl(3, v_term_one_invest_time, 50, 50);
    assert_detail_by_appl(2, v_term_two_invest_time, 100, 100);
  
  END;
  /*
  赎回涉及超过五张申请单（企业）
  */
  PROCEDURE UT_EX_CO_MAX_FIVE_APPL IS
    --out arguements definition
    OUT_FLAG               number;
    OUT_MSG                VARCHAR2(2000);
    V_INVEST_ID            DEMO_INVEST_INFO.INVEST_ID%type := '990001';
    v_plan_id              demo_plan_info.plan_id%type := '000001';
    v_subject_type         demo_emp_invest.subject_type%type := '302101';
    v_co_id                demo_co_invest.co_id%type := '0000001000000';
    v_emp_id               demo_emp_invest.emp_id%type := 'FFFFFFFFFF';
    v_term_one_invest_time VARCHAR2(10) := '2013-01-01';
    v_term_two_invest_time VARCHAR2(10) := '2013-02-01';
    v_red_term_invest_time VARCHAR2(10) := '2013-12-16';
    v_red_amt              demo_invest_pop_tmp.amt%type := 600;
  
  BEGIN
    --准备数据
    --计划数据
    create_plan_info(v_plan_id);
    --账务数据
    create_one_term_acct_for_co(V_INVEST_ID,
                              v_subject_type,
                              v_co_id,
                              1,
                              v_term_one_invest_time,
                              100);
    create_one_term_acct_for_co(V_INVEST_ID,
                              v_subject_type,
                              v_co_id,
                              2,
                              v_term_two_invest_time,
                              100);
    create_one_term_acct_for_co(V_INVEST_ID,
                              v_subject_type,
                              v_co_id,
                              3,
                              v_term_one_invest_time,
                              100);
    create_one_term_acct_for_co(V_INVEST_ID,
                              v_subject_type,
                              v_co_id,
                              4,
                              v_term_one_invest_time,
                              100);
    create_one_term_acct_for_co(V_INVEST_ID,
                              v_subject_type,
                              v_co_id,
                              5,
                              v_term_one_invest_time,
                              100);
    create_one_term_acct_for_co(V_INVEST_ID,
                              v_subject_type,
                              v_co_id,
                              6,
                              v_term_one_invest_time,
                              100);
  
    --预期收益产品准备
    create_ex_prod_info(V_INVEST_ID, v_plan_id);
  
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 1, v_term_one_invest_time);
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 2, v_term_two_invest_time);
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id,
       3,
       1,
       to_char(to_date(v_red_term_invest_time, 'yyyy-mm-dd') - 1,
               'yyyy-mm-dd'));
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 12, v_red_term_invest_time);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_term_one_invest_time, v_plan_id, 1, 1);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_term_two_invest_time, v_plan_id, 1, 2);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_red_term_invest_time, v_plan_id, 1, 3);
  
    --传入数据
    insert into demo_invest_pop_tmp
      (EMP_ID, CO_ID, SUBJECT_TYPE, AMT)
    values
      (v_emp_id, v_co_id, v_subject_type, v_red_amt);
  
    --执行被测代码
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => V_INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
  
    --执行asserts
    --校验程序返回标志
    utassert.eq(msg_in          => 'check OUT_FLAG',
                check_this_in   => OUT_FLAG,
                against_this_in => 3);
    --校验程序返回信息
    utassert.eq(msg_in          => 'check OUT_MSG',
                check_this_in   => OUT_MSG,
                against_this_in => '企业：' ||
                                   PKG_DEMO_COMMON.FUNC_GET_COFNAMEBYID(v_co_id) ||
                                   '生成申请单超过5条');
  
    --根据申请单号校验数据
    assert_detail_by_appl(1, v_term_one_invest_time, 100, 100);
    assert_detail_by_appl(3, v_term_one_invest_time, 100, 100);
    assert_detail_by_appl(2, v_term_two_invest_time, 100, 100);
    assert_detail_by_appl(4, v_term_one_invest_time, 100, 100);
    assert_detail_by_appl(5, v_term_one_invest_time, 100, 100);
    assert_detail_by_appl(6, v_term_one_invest_time, 100, 100);
  
  END;
  /*
  净值报价型，个人赎回
  */
  PROCEDURE UT_UNEX_EMP_ENOUGH IS
    --out arguements definition
    OUT_FLAG               number;
    OUT_MSG                VARCHAR2(2000);
    V_INVEST_ID            DEMO_INVEST_INFO.INVEST_ID%type := '990001';
    v_plan_id              demo_plan_info.plan_id%type := '000001';
    v_subject_type         demo_emp_invest.subject_type%type := '301001';
    v_co_id                demo_co_invest.co_id%type := '0000001000000';
    v_emp_id               demo_emp_invest.emp_id%type := '0000000001';
    v_term_one_invest_time VARCHAR2(10) := '2013-01-01';
    v_red_term_invest_time VARCHAR2(10) := '2013-12-16';
    v_red_amt              demo_invest_pop_tmp.amt%type := 50;
    
  
  BEGIN
    --准备数据
    --计划数据
    create_plan_info(v_plan_id);
    --预期收益产品准备
    create_unex_prod_info(V_INVEST_ID, v_plan_id);
    --账务数据
    insert into demo_emp_invest
      (EMP_ID, CO_ID, SUBJECT_TYPE, INVEST_ID, AMT, QUOTIENT, SET_VALUE)
    values
      (v_emp_id, v_co_id, v_subject_type, V_INVEST_ID, 50, 50, 100);
  
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 1, v_term_one_invest_time);
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id,
       3,
       1,
       to_char(to_date(v_red_term_invest_time, 'yyyy-mm-dd') - 1,
               'yyyy-mm-dd'));
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 12, v_red_term_invest_time);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_term_one_invest_time, v_plan_id, 1, 2);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_red_term_invest_time, v_plan_id, 1, 3);
  
    --传入数据
    insert into demo_invest_pop_tmp
      (EMP_ID, CO_ID, SUBJECT_TYPE, AMT)
    values
      (v_emp_id, v_co_id, v_subject_type, v_red_amt);
  
    --执行被测代码
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => V_INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
    --执行asserts
    --校验程序返回标志
    assert_return_success(OUT_FLAG, OUT_MSG);
  
    --校验拆分对象
    assert_redemption_obj(v_subject_type, v_co_id, v_emp_id);
  
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
  净值报价型，企业赎回
  */
  PROCEDURE UT_UNEX_CO_ENOUGH IS
    --out arguements definition
    OUT_FLAG               number;
    OUT_MSG                VARCHAR2(2000);
    V_INVEST_ID            DEMO_INVEST_INFO.INVEST_ID%type := '990001';
    v_plan_id              demo_plan_info.plan_id%type := '000001';
    v_subject_type         demo_emp_invest.subject_type%type := '301001';
    v_co_id                demo_co_invest.co_id%type := '0000001000000';
    v_emp_id               demo_emp_invest.emp_id%type := 'FFFFFFFFFF';
    v_term_one_invest_time VARCHAR2(10) := '2013-01-01';
    v_red_term_invest_time VARCHAR2(10) := '2013-12-16';
    v_red_amt              demo_invest_pop_tmp.amt%type := 50;
  
  BEGIN
    --准备数据
    --计划数据
    create_plan_info(v_plan_id);
    --预期收益产品准备
    create_unex_prod_info(V_INVEST_ID, v_plan_id);
    --账务数据
    insert into demo_co_invest
      (CO_ID, SUBJECT_TYPE, INVEST_ID, AMT, QUOTIENT, SET_VALUE)
    values
      (v_co_id, v_subject_type, V_INVEST_ID, 50, 50, 100);
  
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 1, v_term_one_invest_time);
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id,
       3,
       1,
       to_char(to_date(v_red_term_invest_time, 'yyyy-mm-dd') - 1,
               'yyyy-mm-dd'));
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 12, v_red_term_invest_time);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_term_one_invest_time, v_plan_id, 1, 2);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_red_term_invest_time, v_plan_id, 1, 3);
  
    --传入数据
    insert into demo_invest_pop_tmp
      (EMP_ID, CO_ID, SUBJECT_TYPE, AMT)
    values
      (v_emp_id, v_co_id, v_subject_type, v_red_amt);
  
    --执行被测代码
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => V_INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
    --执行asserts
    --校验程序返回标志
    assert_return_success(OUT_FLAG, OUT_MSG);
  
    --校验拆分对象
    assert_redemption_obj(v_subject_type, v_co_id, v_emp_id);
  
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
    OUT_FLAG               number;
    OUT_MSG                VARCHAR2(2000);
    V_INVEST_ID            DEMO_INVEST_INFO.INVEST_ID%type := '990001';
    v_plan_id              demo_plan_info.plan_id%type := '000001';
    v_subject_type         demo_emp_invest.subject_type%type := '301001';
    v_co_id                demo_co_invest.co_id%type := '0000001000000';
    v_emp_id               demo_emp_invest.emp_id%type := 'FFFFFFFFFF';
    v_term_one_invest_time VARCHAR2(10) := '2013-01-01';
    v_red_term_invest_time VARCHAR2(10) := '2013-12-16';
    v_red_amt              demo_invest_pop_tmp.amt%type := 100;
  
  BEGIN
    --准备数据
    --计划数据
    create_plan_info(v_plan_id);
    --预期收益产品准备
    create_unex_prod_info(V_INVEST_ID, v_plan_id);
    --账务数据
    insert into demo_co_invest
      (CO_ID, SUBJECT_TYPE, INVEST_ID, AMT, QUOTIENT, SET_VALUE)
    values
      (v_co_id, v_subject_type, V_INVEST_ID, 50, 50, 100);
  
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 1, v_term_one_invest_time);
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id,
       3,
       1,
       to_char(to_date(v_red_term_invest_time, 'yyyy-mm-dd') - 1,
               'yyyy-mm-dd'));
    insert into demo_invest_op_control
      (INVEST_ID, OP_TYPE, TERM_NO, INVEST_TIME)
    values
      (v_invest_id, 2, 12, v_red_term_invest_time);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_term_one_invest_time, v_plan_id, 1, 2);
  
    insert into demo_invest_unit_value
      (INVEST_ID, EVALUATE_DATE, PLAN_ID, UNIT_VALUE, EVAL_STATE_FLAG)
    values
      (v_invest_id, v_red_term_invest_time, v_plan_id, 1, 3);
  
    --传入数据
    insert into demo_invest_pop_tmp
      (EMP_ID, CO_ID, SUBJECT_TYPE, AMT)
    values
      (v_emp_id, v_co_id, v_subject_type, v_red_amt);
  
    --执行被测代码
    pkg_demo.PROC_DEAL_POP(I_INVEST_ID => V_INVEST_ID,
                           O_FLAG      => OUT_FLAG,
                           O_MSG       => OUT_MSG);
    --执行asserts
    --校验程序返回标志
    utassert.eq(msg_in          => 'check OUT_FLAG',
                check_this_in   => OUT_FLAG,
                against_this_in => 2);
    --校验程序返回信息
    utassert.eq(msg_in          => 'check OUT_MSG',
                check_this_in   => OUT_MSG,
                against_this_in => '赎回份额分配出错');
  
  END;

  procedure create_plan_info(plan_id in demo_plan_info.plan_id%type) is
  begin
    insert into demo_plan_info
      (PLAN_ID, PLAN_NAME, PLAN_TIME)
    values
      (plan_id, '计划名称', '2013-12-01');
  end create_plan_info;

  procedure create_ex_prod_info(invest_id in DEMO_INVEST_INFO.INVEST_ID%type,
                                plan_id   in demo_plan_info.plan_id%type) is
  True constant number := 0;
  begin
    create_prod_info(invest_id, plan_id, True);
  end create_ex_prod_info;

  procedure create_unex_prod_info(invest_id in DEMO_INVEST_INFO.INVEST_ID%type,
                                  plan_id   in demo_plan_info.plan_id%type) is
  False constant number := 1;
  begin
    create_prod_info(invest_id, plan_id, False);
  end create_unex_prod_info;

  procedure create_prod_info(invest_id in DEMO_INVEST_INFO.INVEST_ID%type,
                             plan_id   in demo_plan_info.plan_id%type,
                             buy_way in demo_invest_basic_info.BUY_WAY%type) is
    fpps_invest_id demo_invest_basic_info.fpps_invest_id%type := '00000001';
    Dummy constant number := 1;
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
      (fpps_invest_id, invest_id, Dummy, Dummy, buy_way, 1, 1, Dummy, Dummy);
  end create_prod_info;

  procedure assert_redemption_obj(expected_subject_type in demo_emp_invest.subject_type%type,
                       expected_co_id        in demo_co_invest.co_id%type,
                       expected_emp_id       in demo_emp_invest.emp_id%type) is
  begin
    utassert.eqqueryvalue(msg_in           => '校验co_id',
                          CHECK_QUERY_IN   => 'select distinct co_id from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => expected_co_id);
    utassert.eqqueryvalue(msg_in           => '校验emp_id',
                          CHECK_QUERY_IN   => 'select distinct emp_id from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => expected_emp_id);
    utassert.eqqueryvalue(msg_in           => '校验subject_type',
                          CHECK_QUERY_IN   => 'select distinct subject_type from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => expected_subject_type);
  end assert_redemption_obj;

  procedure assert_return_success(expected_out_flag in number,
                                  expected_out_msg in VARCHAR2) is
  begin
    utassert.eq(msg_in          => '校验程序返回标志',
                check_this_in   => expected_out_flag,
                against_this_in => 0);
    utassert.eq(msg_in          => '校验程序返回信息',
                check_this_in   => expected_out_msg,
                against_this_in => '成功');
  end assert_return_success;

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

  procedure create_one_term_acct_for_emp(invest_id in DEMO_INVEST_INFO.INVEST_ID%type,
                                       subject_type in demo_emp_invest.subject_type%type,
                                       co_id        in demo_co_invest.co_id%type,
                                       emp_id       in demo_emp_invest.emp_id%type,
                                       appl_num     in demo_appl_num_rel.appl_num%type,
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
                  subject_type subject_type,
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
                  subject_type subject_type,
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

  procedure create_one_term_acct_for_co(invest_id in DEMO_INVEST_INFO.INVEST_ID%type,
                                        subject_type in demo_emp_invest.subject_type%type,
                                        co_id        in demo_co_invest.co_id%type,
                                        appl_num     in demo_appl_num_rel.appl_num%type,
                                        invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                        amt          in demo_appl_num_rel.AMT%type) is
  begin
    insert into demo_appl_num_rel
      (CO_ID, INVEST_ID, APPL_NUM, INVEST_TIME, AMT, RED_AMT)
    values
      (co_id, invest_id, appl_num, invest_time, amt, 0.00);
  
    merge into demo_co_invest a
    using (select co_id        co_id,
                  subject_type subject_type,
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
                  subject_type subject_type,
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

  function one_day_before(day VARCHAR2) return VARCHAR2 is
  begin
    return to_char(to_date(day, 'yyyy-mm-dd') - 1, 'yyyy-mm-dd');
  end;
END UT_PKG_DEMO_PROC_POP_DEAL;
/

set serveroutput on
/

exec utplsql.run ('UT_PKG_DEMO_PROC_POP_DEAL', per_method_setup_in => TRUE)
/
