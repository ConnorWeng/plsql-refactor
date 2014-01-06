CREATE OR REPLACE PACKAGE UT_PKG_DEMO_COMMON IS
  procedure create_plan_info;
  procedure create_prod_info(buy_way in demo_invest_basic_info.BUY_WAY%type);
  procedure create_one_purchase_for_op_ctl(invest_time VARCHAR2, op_control_purchase_term_no in out number);
  procedure create_one_item_for_op_ctl(op_type number, term_no number, invest_time VARCHAR2);
  procedure create_red_pur_for_op_ctl(red_term_invest_time VARCHAR2, op_control_purchase_term_no in out number);

  function one_day_before(day VARCHAR2) return VARCHAR2;

  Dummy                             constant number := 99;

  invest_id                         constant DEMO_INVEST_INFO.INVEST_ID%type := '990001';
  plan_id                           constant demo_plan_info.plan_id%type := '000001';
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

  function one_day_before(day VARCHAR2) return VARCHAR2 is
  begin
    return to_char(to_date(day, 'yyyy-mm-dd') - 1, 'yyyy-mm-dd');
  end;

END UT_PKG_DEMO_COMMON;
/
