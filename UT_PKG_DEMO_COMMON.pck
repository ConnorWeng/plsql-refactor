CREATE OR REPLACE PACKAGE UT_PKG_DEMO_COMMON IS
  procedure create_plan_info;
  procedure create_prod_info(buy_way in demo_invest_basic_info.BUY_WAY%type);

  Dummy                             constant number := 99;

  invest_id                         constant DEMO_INVEST_INFO.INVEST_ID%type := '990001';
  plan_id                           constant demo_plan_info.plan_id%type := '000001';

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

END UT_PKG_DEMO_COMMON;
/
