CREATE OR REPLACE PACKAGE UT_PKG_DEMO_PROC_POP_DEAL IS
  PROCEDURE UT_SETUP;
  PROCEDURE UT_TEARDOWN;
  procedure proc_plan_info_prepare(v_plan_id in demo_plan_info.plan_id%type);
  procedure proc_ex_prod_info_prepare(V_INVEST_ID in DEMO_INVEST_INFO.INVEST_ID%type,
                                      v_plan_id   in demo_plan_info.plan_id%type);
  procedure proc_unex_prod_info_prepare(V_INVEST_ID in DEMO_INVEST_INFO.INVEST_ID%type,
                                        v_plan_id   in demo_plan_info.plan_id%type);
  procedure proc_assert_obj(v_subject_type in demo_emp_invest.subject_type%type,
                            v_co_id        in demo_co_invest.co_id%type,
                            v_emp_id       in demo_emp_invest.emp_id%type);
  procedure proc_assert_return_success(OUT_FLAG in number,
                                       OUT_MSG  in VARCHAR2);
  procedure proc_assert_detail_by_appl(i_yappl_num   in number,
                                       i_invest_time in varchar2,
                                       i_quotient    in number,
                                       i_amt         in number);
  procedure proc_emp_add_one_term_acct(V_INVEST_ID    in DEMO_INVEST_INFO.INVEST_ID%type,
                                       v_subject_type in demo_emp_invest.subject_type%type,
                                       v_co_id        in demo_co_invest.co_id%type,
                                       v_emp_id       in demo_emp_invest.emp_id%type,
                                       v_appl_num     in demo_appl_num_rel.appl_num%type,
                                       v_invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                       v_amt          in demo_appl_num_rel.AMT%type);
  procedure proc_co_add_one_term_acct(V_INVEST_ID    in DEMO_INVEST_INFO.INVEST_ID%type,
                                      v_subject_type in demo_emp_invest.subject_type%type,
                                      v_co_id        in demo_co_invest.co_id%type,
                                      v_appl_num     in demo_appl_num_rel.appl_num%type,
                                      v_invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                      v_amt          in demo_appl_num_rel.AMT%type);
  -- For each program to test...
  PROCEDURE UT_EX_EMP_ONE_TERM_ONE_APPL;
  PROCEDURE UT_EX_EMP_MULT_TERM_ONE_APPL;
  PROCEDURE UT_EX_EMP_MULT_TERM_MULT_APPL;
  PROCEDURE UT_EX_EMP_MULT_TERM_NOTENOUGH;
  PROCEDURE UT_EX_CO_MULT_TERM;
  PROCEDURE UT_EX_CO_MAX_FIVE_APPL;
  PROCEDURE UT_UNEX_EMP_ENOUGH;
  PROCEDURE UT_UNEX_CO_ENOUGH;
  PROCEDURE UT_UNEX_CO_NOTENOUGH;
END UT_PKG_DEMO_PROC_POP_DEAL;
/
CREATE OR REPLACE PACKAGE BODY UT_PKG_DEMO_PROC_POP_DEAL IS
  PROCEDURE UT_SETUP IS
  BEGIN
    /* --计划数据
    execute immediate 'truncate table demo_plan_info';
    
    --产品数据
    execute immediate 'truncate table demo_invest_info';
    execute immediate 'truncate table demo_invest_basic_info';
    execute immediate 'truncate table demo_invest_op_control';
    execute immediate 'truncate table demo_invest_unit_value';
    
    --账务数据
    execute immediate 'truncate table demo_appl_num_rel';
    execute immediate 'truncate table demo_emp_invest';
    execute immediate 'truncate table demo_emp_invest_term';
    execute immediate 'truncate table demo_co_invest';
    execute immediate 'truncate table demo_co_invest_term';
    
    --传入数据
    execute immediate 'truncate table demo_invest_pop_tmp';
    
    --传出数据
    execute immediate 'truncate table demo_invest_pop_result_tmp';*/
    null;
  END;
  PROCEDURE UT_TEARDOWN IS
  BEGIN
    rollback;
  END;
  -- Refactored procedure proc_plan_info_prepare 
  procedure proc_plan_info_prepare(v_plan_id in demo_plan_info.plan_id%type) is
  begin
    --计划数据
    insert into demo_plan_info
      (PLAN_ID, PLAN_NAME, PLAN_TIME)
    values
      (v_plan_id, '计划名称', '2013-12-01');
  end proc_plan_info_prepare;
  -- Refactored procedure proc_ex_prod_info_prepare 
  procedure proc_ex_prod_info_prepare(V_INVEST_ID in DEMO_INVEST_INFO.INVEST_ID%type,
                                      v_plan_id   in demo_plan_info.plan_id%type) is
    v_fpps_invest_id demo_invest_basic_info.fpps_invest_id%type := '00000001';
  begin
    --产品数据
    insert into demo_invest_info
      (PLAN_ID, INVEST_ID, INVEST_NAME)
    values
      (v_plan_id, v_invest_id, '组合名称');
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
      (v_fpps_invest_id, v_invest_id, 1, 4, 0, 1, 1, 3, 1);
  end proc_ex_prod_info_prepare;
  procedure proc_unex_prod_info_prepare(V_INVEST_ID in DEMO_INVEST_INFO.INVEST_ID%type,
                                        v_plan_id   in demo_plan_info.plan_id%type) is
    v_fpps_invest_id demo_invest_basic_info.fpps_invest_id%type := '00000001';
  begin
    --产品数据
    insert into demo_invest_info
      (PLAN_ID, INVEST_ID, INVEST_NAME)
    values
      (v_plan_id, v_invest_id, '组合名称');
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
      (v_fpps_invest_id, v_invest_id, 1, 4, 1, 1, 1, 3, 1);
  end proc_unex_prod_info_prepare;
  -- Refactored procedure proc_obj_assert 
  procedure proc_assert_obj(v_subject_type in demo_emp_invest.subject_type%type,
                            v_co_id        in demo_co_invest.co_id%type,
                            v_emp_id       in demo_emp_invest.emp_id%type) is
  begin
    --校验co_id
    utassert.eqqueryvalue(msg_in           => 'check co_id',
                          CHECK_QUERY_IN   => 'select distinct co_id from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => v_co_id);
    --校验emp_id
    utassert.eqqueryvalue(msg_in           => 'check emp_id',
                          CHECK_QUERY_IN   => 'select distinct emp_id from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => v_emp_id);
  
    --校验subject_type
    utassert.eqqueryvalue(msg_in           => 'check subject_type',
                          CHECK_QUERY_IN   => 'select distinct subject_type from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => v_subject_type);
  end proc_assert_obj;
  -- Refactored procedure proc_return_msg_assert 
  procedure proc_assert_return_success(OUT_FLAG in number,
                                       OUT_MSG  in VARCHAR2) is
  begin
    --校验程序返回标志
    utassert.eq(msg_in          => 'check OUT_FLAG',
                check_this_in   => OUT_FLAG,
                against_this_in => 0);
    --校验程序返回信息
    utassert.eq(msg_in          => 'check OUT_MSG',
                check_this_in   => OUT_MSG,
                against_this_in => '成功');
  end proc_assert_return_success;
  -- Refactored procedure proc_assert_detail_by_appl 
  procedure proc_assert_detail_by_appl(i_yappl_num   in number,
                                       i_invest_time in varchar2,
                                       i_quotient    in number,
                                       i_amt         in number) is
  begin
    --校验invest_time
    utassert.eqqueryvalue(msg_in           => 'check invest_time',
                          CHECK_QUERY_IN   => 'select invest_time from demo_invest_pop_result_tmp where YAPPL_NUM = ' ||
                                              i_yappl_num,
                          AGAINST_VALUE_IN => i_invest_time);
  
    --校验quotient
    utassert.eqqueryvalue(msg_in           => 'check quotient',
                          CHECK_QUERY_IN   => 'select quotient from demo_invest_pop_result_tmp where YAPPL_NUM = ' ||
                                              i_yappl_num,
                          AGAINST_VALUE_IN => i_quotient);
  
    --校验amt
    utassert.eqqueryvalue(msg_in           => 'check amt',
                          CHECK_QUERY_IN   => 'select amt from demo_invest_pop_result_tmp where YAPPL_NUM = ' ||
                                              i_yappl_num,
                          AGAINST_VALUE_IN => i_amt);
  end proc_assert_detail_by_appl;
  -- Refactored procedure proc_add_one_term_acct 
  procedure proc_emp_add_one_term_acct(V_INVEST_ID    in DEMO_INVEST_INFO.INVEST_ID%type,
                                       v_subject_type in demo_emp_invest.subject_type%type,
                                       v_co_id        in demo_co_invest.co_id%type,
                                       v_emp_id       in demo_emp_invest.emp_id%type,
                                       v_appl_num     in demo_appl_num_rel.appl_num%type,
                                       v_invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                       v_amt          in demo_appl_num_rel.AMT%type) is
  begin
    insert into demo_appl_num_rel
      (CO_ID, INVEST_ID, APPL_NUM, INVEST_TIME, AMT, RED_AMT)
    values
      (v_co_id, v_invest_id, v_appl_num, v_invest_time, v_amt, 0.00);
  
    merge into demo_emp_invest a
    using (select v_emp_id       emp_id,
                  v_co_id        co_id,
                  v_subject_type subject_type,
                  v_invest_id    invest_id,
                  v_amt          amt
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
    using (select v_emp_id       emp_id,
                  v_co_id        co_id,
                  v_subject_type subject_type,
                  v_invest_id    invest_id,
                  v_invest_time  invest_time,
                  v_amt          amt
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
  
  end proc_emp_add_one_term_acct;
  -- Refactored procedure proc_add_one_term_acct 
  procedure proc_co_add_one_term_acct(V_INVEST_ID    in DEMO_INVEST_INFO.INVEST_ID%type,
                                      v_subject_type in demo_emp_invest.subject_type%type,
                                      v_co_id        in demo_co_invest.co_id%type,
                                      v_appl_num     in demo_appl_num_rel.appl_num%type,
                                      v_invest_time  in demo_appl_num_rel.INVEST_TIME%type,
                                      v_amt          in demo_appl_num_rel.AMT%type) is
  begin
    insert into demo_appl_num_rel
      (CO_ID, INVEST_ID, APPL_NUM, INVEST_TIME, AMT, RED_AMT)
    values
      (v_co_id, v_invest_id, v_appl_num, v_invest_time, v_amt, 0.00);
  
    merge into demo_co_invest a
    using (select v_co_id        co_id,
                  v_subject_type subject_type,
                  v_invest_id    invest_id,
                  v_amt          amt
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
    using (select v_co_id        co_id,
                  v_subject_type subject_type,
                  v_invest_id    invest_id,
                  v_invest_time  invest_time,
                  v_amt          amt
             from dual) b
    on (a.co_id = b.co_id and a.subject_type = b.subject_type and a.invest_id = b.invest_id and a.invest_time = b.invest_time)
    WHEN MATCHED THEN
      UPDATE SET A.AMT = a.AMT + b.amt
    when not matched then
      insert
        (CO_ID, SUBJECT_TYPE, INVEST_ID, invest_time, AMT)
      values
        (b.co_id, b.subject_type, b.invest_id, b.invest_time, b.amt);
  
  end proc_co_add_one_term_acct;
  /*
  涉及一期，且一期只有一张申请单，一期资产够（个人）
  */
  PROCEDURE UT_EX_EMP_ONE_TERM_ONE_APPL IS
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
    v_red_amt              demo_invest_pop_tmp.amt%type := 90;
    
  
  BEGIN
    --准备数据
    proc_plan_info_prepare(v_plan_id);
    --账务数据
    proc_emp_add_one_term_acct(V_INVEST_ID,
                               v_subject_type,
                               v_co_id,
                               v_emp_id,
                               1,
                               v_term_one_invest_time,
                               100);
  
    --预期收益产品准备
    proc_ex_prod_info_prepare(V_INVEST_ID, v_plan_id);
  
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
      (v_invest_id, 2, 2, v_red_term_invest_time);
  
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
    --校验返回信息
    proc_assert_return_success(OUT_FLAG, OUT_MSG);
    --校验拆分对象
    proc_assert_obj(v_subject_type, v_co_id, v_emp_id);
  
    --校验tablecount
    utassert.eqqueryvalue(msg_in           => 'check tablecount',
                          CHECK_QUERY_IN   => 'select count(1) from demo_invest_pop_result_tmp',
                          AGAINST_VALUE_IN => 1);
  
    --根据申请单号校验数据
    proc_assert_detail_by_appl(1, v_term_one_invest_time, 90, 90);
  
  END;
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
    proc_plan_info_prepare(v_plan_id);
    --账务数据
    proc_emp_add_one_term_acct(V_INVEST_ID,
                               v_subject_type,
                               v_co_id,
                               v_emp_id,
                               1,
                               v_term_one_invest_time,
                               100);
    proc_emp_add_one_term_acct(V_INVEST_ID,
                               v_subject_type,
                               v_co_id,
                               v_emp_id,
                               2,
                               v_term_two_invest_time,
                               100);
  
    --预期收益产品准备
    proc_ex_prod_info_prepare(V_INVEST_ID, v_plan_id);
  
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
    proc_assert_return_success(OUT_FLAG, OUT_MSG);
    --校验拆分对象
    proc_assert_obj(v_subject_type, v_co_id, v_emp_id);
  
    --根据申请单号校验数据
    proc_assert_detail_by_appl(1, v_term_one_invest_time, 80, 80);
    proc_assert_detail_by_appl(2, v_term_two_invest_time, 100, 100);
  
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
    proc_plan_info_prepare(v_plan_id);
    --账务数据
    proc_emp_add_one_term_acct(V_INVEST_ID,
                               v_subject_type,
                               v_co_id,
                               v_emp_id,
                               1,
                               v_term_one_invest_time,
                               100);
    proc_emp_add_one_term_acct(V_INVEST_ID,
                               v_subject_type,
                               v_co_id,
                               v_emp_id,
                               2,
                               v_term_two_invest_time,
                               100);
    proc_emp_add_one_term_acct(V_INVEST_ID,
                               v_subject_type,
                               v_co_id,
                               v_emp_id,
                               3,
                               v_term_one_invest_time,
                               100);
  
    --预期收益产品准备
    proc_ex_prod_info_prepare(V_INVEST_ID, v_plan_id);
  
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
    proc_assert_return_success(OUT_FLAG, OUT_MSG);
    --校验拆分对象
    proc_assert_obj(v_subject_type, v_co_id, v_emp_id);
  
    --根据申请单号校验数据
    proc_assert_detail_by_appl(1, v_term_one_invest_time, 50, 50);
    proc_assert_detail_by_appl(3, v_term_one_invest_time, 100, 100);
    proc_assert_detail_by_appl(2, v_term_two_invest_time, 100, 100);
  
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
    proc_plan_info_prepare(v_plan_id);
    --账务数据
    proc_emp_add_one_term_acct(V_INVEST_ID,
                               v_subject_type,
                               v_co_id,
                               v_emp_id,
                               1,
                               v_term_one_invest_time,
                               100);
    proc_emp_add_one_term_acct(V_INVEST_ID,
                               v_subject_type,
                               v_co_id,
                               v_emp_id,
                               2,
                               v_term_two_invest_time,
                               100);
    proc_emp_add_one_term_acct(V_INVEST_ID,
                               v_subject_type,
                               v_co_id,
                               v_emp_id,
                               3,
                               v_term_one_invest_time,
                               100);
  
    --预期收益产品准备
    proc_ex_prod_info_prepare(V_INVEST_ID, v_plan_id);
  
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
    proc_plan_info_prepare(v_plan_id);
    --账务数据
    proc_co_add_one_term_acct(V_INVEST_ID,
                              v_subject_type,
                              v_co_id,
                              1,
                              v_term_one_invest_time,
                              100);
    proc_co_add_one_term_acct(V_INVEST_ID,
                              v_subject_type,
                              v_co_id,
                              2,
                              v_term_two_invest_time,
                              100);
    proc_co_add_one_term_acct(V_INVEST_ID,
                              v_subject_type,
                              v_co_id,
                              3,
                              v_term_one_invest_time,
                              100);
  
    --预期收益产品准备
    proc_ex_prod_info_prepare(V_INVEST_ID, v_plan_id);
  
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
    proc_assert_return_success(OUT_FLAG, OUT_MSG);
    --校验拆分对象
    proc_assert_obj(v_subject_type, v_co_id, v_emp_id);
  
    --根据申请单号校验数据
    proc_assert_detail_by_appl(1, v_term_one_invest_time, 50, 50);
    proc_assert_detail_by_appl(3, v_term_one_invest_time, 100, 100);
    proc_assert_detail_by_appl(2, v_term_two_invest_time, 100, 100);
  
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
    proc_plan_info_prepare(v_plan_id);
    --账务数据
    proc_co_add_one_term_acct(V_INVEST_ID,
                              v_subject_type,
                              v_co_id,
                              1,
                              v_term_one_invest_time,
                              100);
    proc_co_add_one_term_acct(V_INVEST_ID,
                              v_subject_type,
                              v_co_id,
                              2,
                              v_term_two_invest_time,
                              100);
    proc_co_add_one_term_acct(V_INVEST_ID,
                              v_subject_type,
                              v_co_id,
                              3,
                              v_term_one_invest_time,
                              100);
    proc_co_add_one_term_acct(V_INVEST_ID,
                              v_subject_type,
                              v_co_id,
                              4,
                              v_term_one_invest_time,
                              100);
    proc_co_add_one_term_acct(V_INVEST_ID,
                              v_subject_type,
                              v_co_id,
                              5,
                              v_term_one_invest_time,
                              100);
    proc_co_add_one_term_acct(V_INVEST_ID,
                              v_subject_type,
                              v_co_id,
                              6,
                              v_term_one_invest_time,
                              100);
  
    --预期收益产品准备
    proc_ex_prod_info_prepare(V_INVEST_ID, v_plan_id);
  
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
    proc_assert_detail_by_appl(1, v_term_one_invest_time, 100, 100);
    proc_assert_detail_by_appl(3, v_term_one_invest_time, 100, 100);
    proc_assert_detail_by_appl(2, v_term_two_invest_time, 100, 100);
    proc_assert_detail_by_appl(4, v_term_one_invest_time, 100, 100);
    proc_assert_detail_by_appl(5, v_term_one_invest_time, 100, 100);
    proc_assert_detail_by_appl(6, v_term_one_invest_time, 100, 100);
  
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
    proc_plan_info_prepare(v_plan_id);
    --预期收益产品准备
    proc_unex_prod_info_prepare(V_INVEST_ID, v_plan_id);
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
    proc_assert_return_success(OUT_FLAG, OUT_MSG);
  
    --校验拆分对象
    proc_assert_obj(v_subject_type, v_co_id, v_emp_id);
  
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
    proc_plan_info_prepare(v_plan_id);
    --预期收益产品准备
    proc_unex_prod_info_prepare(V_INVEST_ID, v_plan_id);
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
    proc_assert_return_success(OUT_FLAG, OUT_MSG);
  
    --校验拆分对象
    proc_assert_obj(v_subject_type, v_co_id, v_emp_id);
  
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
    proc_plan_info_prepare(v_plan_id);
    --预期收益产品准备
    proc_unex_prod_info_prepare(V_INVEST_ID, v_plan_id);
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
END UT_PKG_DEMO_PROC_POP_DEAL;
/

set serveroutput on
/

exec utplsql.run ('UT_PKG_DEMO_PROC_POP_DEAL', per_method_setup_in => TRUE)
/
