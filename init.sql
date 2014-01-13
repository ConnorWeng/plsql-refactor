-- Create table
create table DB_LOG
(
  id              VARCHAR2(20),
  proc_name       VARCHAR2(100),
  info            VARCHAR2(4000),
  log_level       VARCHAR2(10),
  time_stamp      VARCHAR2(23),
  error_backtrace VARCHAR2(4000),
  err_stack       VARCHAR2(4000),
  step_no         VARCHAR2(20),
  log_date        VARCHAR2(8)
);
-- Add comments to the table 
comment on table DB_LOG
  is '���ݿ���־��Ϣ��';
-- Add comments to the columns 
comment on column DB_LOG.id
  is 'ID';
comment on column DB_LOG.proc_name
  is '������';
comment on column DB_LOG.info
  is 'ժҪ';
comment on column DB_LOG.log_level
  is '��־�ȼ�';
comment on column DB_LOG.time_stamp
  is 'ʱ���';
comment on column DB_LOG.error_backtrace
  is '�������';
comment on column DB_LOG.err_stack
  is '�����ջ';
comment on column DB_LOG.step_no
  is '����';
comment on column DB_LOG.log_date
  is '��־����';
-- Create/Recreate indexes 
create index IDX_DB_LOG_1 on DB_LOG (PROC_NAME, LOG_DATE);
create index IDX_DB_LOG_2 on DB_LOG (LOG_DATE, LOG_LEVEL);

-- Create table
create table demo_PLAN_INFO
(
  plan_id             CHAR(6) not null,
  plan_name           VARCHAR2(100) not null,
  plan_time           VARCHAR2(10) not null
);
-- Add comments to the table 
comment on table demo_PLAN_INFO
  is '�ƻ�������Ϣ��';
-- Add comments to the columns 
comment on column demo_PLAN_INFO.plan_id
  is '�ƻ�����';
comment on column demo_PLAN_INFO.plan_name
  is '�ƻ�����';
comment on column demo_PLAN_INFO.plan_time
  is '�ƻ���ǰʱ��';
-- Create/Recreate primary, unique and foreign key constraints 
alter table demo_PLAN_INFO
  add constraint PK_demo_PLAN_INFO primary key (PLAN_ID);
-- Create/Recreate indexes 
create index IDX_demo_PLAN_INFO_1 on demo_PLAN_INFO (PLAN_NAME);

-- Create table
create table DEMO_INVEST_OP_CONTROL
(
  invest_id       CHAR(6) not null,
  op_type         NUMBER(2) not null,
  term_no         NUMBER(10) not null,
  invest_time     VARCHAR2(10) not null,
  lcr_way         NUMBER(2),
  unit_value_date CHAR(10)
);
-- Add comments to the table 
comment on table DEMO_INVEST_OP_CONTROL
  is '���׿��Ʊ�';
-- Add comments to the columns 
comment on column DEMO_INVEST_OP_CONTROL.invest_id
  is '��ϱ���';
comment on column DEMO_INVEST_OP_CONTROL.op_type
  is 'ҵ�����ࣨ1���Ϲ� 2������ 3����� 4���ֺ� 5������ 6��ǿ�� 7��ǿ����';
comment on column DEMO_INVEST_OP_CONTROL.term_no
  is 'ҵ�������ڴκ�';
comment on column DEMO_INVEST_OP_CONTROL.invest_time
  is 'ȷ������';
comment on column DEMO_INVEST_OP_CONTROL.lcr_way
  is '������㷽ʽ��1.���� 2.�껯 3.�̶����� 4.Ϣ�ࣩ';
comment on column DEMO_INVEST_OP_CONTROL.unit_value_date
  is '��ֵʹ������';
-- Create/Recreate primary, unique and foreign key constraints 
alter table DEMO_INVEST_OP_CONTROL
  add constraint PK_DEMO_INVEST_OP_CONTROL primary key (INVEST_ID, INVEST_TIME, OP_TYPE)
  using index ;
-- Create/Recreate indexes 
create unique index IDX_DEMO_INVEST_OP_CONTROL_1 on DEMO_INVEST_OP_CONTROL (INVEST_ID, TERM_NO, OP_TYPE);

-- Create table
create global temporary table DEMO_INVEST_POP_TMP
(
  emp_id       CHAR(10) default 'FFFFFFFFFF' not null,
  co_id        CHAR(13) not null,
  subject_type CHAR(6) not null,
  amt          NUMBER(17,2) not null,
  amt_remain   NUMBER(17,2)
)
on commit preserve rows;
-- Add comments to the table 
comment on table DEMO_INVEST_POP_TMP
  is '����ȳ�������ʱ��';
-- Add comments to the columns 
comment on column DEMO_INVEST_POP_TMP.emp_id
  is '���˱���';
comment on column DEMO_INVEST_POP_TMP.co_id
  is '��ҵ����';
comment on column DEMO_INVEST_POP_TMP.subject_type
  is '��Ŀ';
comment on column DEMO_INVEST_POP_TMP.amt
  is '���';
comment on column DEMO_INVEST_POP_TMP.amt_remain
  is 'ʣ����';
-- Create/Recreate indexes 
create unique index IDX_DEMO_INVEST_POP_TMP_1 on DEMO_INVEST_POP_TMP (EMP_ID, CO_ID, SUBJECT_TYPE);

-- Create table
create global temporary table DEMO_INVEST_POP_RESULT_TMP
(
  emp_id       CHAR(10) default 'FFFFFFFFFF' not null,
  co_id        CHAR(13) not null,
  subject_type CHAR(6) not null,
  invest_time  CHAR(10) not null,
  amt          NUMBER(17,2) not null,
  quotient     NUMBER(17,2),
  yappl_num    NUMBER(17)
)
on commit preserve rows;
-- Add comments to the table 
comment on table DEMO_INVEST_POP_RESULT_TMP
  is '����ȳ�������ϸ��ʱ��';
-- Add comments to the columns 
comment on column DEMO_INVEST_POP_RESULT_TMP.emp_id
  is '���˱���';
comment on column DEMO_INVEST_POP_RESULT_TMP.co_id
  is '��ҵ����';
comment on column DEMO_INVEST_POP_RESULT_TMP.subject_type
  is '��Ŀ';
comment on column DEMO_INVEST_POP_RESULT_TMP.invest_time
  is '����ȷ����������';
comment on column DEMO_INVEST_POP_RESULT_TMP.amt
  is '���';
comment on column DEMO_INVEST_POP_RESULT_TMP.quotient
  is '�ݶ�';
comment on column DEMO_INVEST_POP_RESULT_TMP.yappl_num
  is 'ԭ���뵥��';
-- Create/Recreate indexes 
create unique index IDX_DEMO_INVEST_POP_RESULT_1 on DEMO_INVEST_POP_RESULT_TMP (EMP_ID, CO_ID, SUBJECT_TYPE, INVEST_TIME, YAPPL_NUM);

-- Create table
create table DEMO_INVEST_BASIC_INFO
(
  fpps_invest_id   VARCHAR2(8) not null,
  invest_id        CHAR(6) not null,
  issue_dept       NUMBER(2),
  invest_state     NUMBER(2) not null,
  issue_begin_date CHAR(10),
  issue_end_date   CHAR(10),
  invest_end_date  CHAR(10),
  issue_way        NUMBER(2) not null,
  buy_way          NUMBER(2) not null,
  sell_order       NUMBER(2) not null,
  sell_min_term    NUMBER(3),
  open_sell_term   NUMBER(3),
  issu_min         NUMBER(17,2),
  buy_pa_amt       NUMBER(17,2),
  buy_add_amt_issu NUMBER(17,2),
  buy_level_issu   NUMBER(17,2),
  buy_level_pa     NUMBER(17,2),
  buy_add_amt_pa   NUMBER(17,2),
  sell_value       NUMBER(17,2),
  prod_share_type  NUMBER(3)
);
-- Add comments to the table 
comment on table DEMO_INVEST_BASIC_INFO
  is '��Ʒ���Ա�';
-- Add comments to the columns 
comment on column DEMO_INVEST_BASIC_INFO.fpps_invest_id
  is '��Ʒ����';
comment on column DEMO_INVEST_BASIC_INFO.invest_id
  is 'Ͷ����ϱ���';
comment on column DEMO_INVEST_BASIC_INFO.issue_dept
  is '��Ʒ���в���';
comment on column DEMO_INVEST_BASIC_INFO.invest_state
  is '��Ʒ״̬��1.���� 2.���гɹ� 3.����ʧ�� 9.���ڣ�';
comment on column DEMO_INVEST_BASIC_INFO.issue_begin_date
  is '���п�ʼ��';
comment on column DEMO_INVEST_BASIC_INFO.issue_end_date
  is '���н�����';
comment on column DEMO_INVEST_BASIC_INFO.invest_end_date
  is '��Ʒ������';
comment on column DEMO_INVEST_BASIC_INFO.issue_way
  is '���з�ʽ��1.�ڴη���  4.��Ʒ�ڹ�������ת����';
comment on column DEMO_INVEST_BASIC_INFO.buy_way
  is '�Ƿ��м�������0.�� 1.��';
comment on column DEMO_INVEST_BASIC_INFO.sell_order
  is '��غ���˳��1-�Ƚ��ȳ� 2-�Ƚ���� 3-�����뵥��ţ�';
comment on column DEMO_INVEST_BASIC_INFO.sell_min_term
  is '��ǰ�����ͳ�������';
comment on column DEMO_INVEST_BASIC_INFO.open_sell_term
  is '�����������';
comment on column DEMO_INVEST_BASIC_INFO.issu_min
  is '�����ڵ�����͹�����';
comment on column DEMO_INVEST_BASIC_INFO.buy_pa_amt
  is '�����ڵ�����͹�����';
comment on column DEMO_INVEST_BASIC_INFO.buy_add_amt_issu
  is '׷���Ϲ���ͽ��';
comment on column DEMO_INVEST_BASIC_INFO.buy_level_issu
  is '�����Ϲ��޶�';
comment on column DEMO_INVEST_BASIC_INFO.buy_level_pa
  is '�����깺�޶�';
comment on column DEMO_INVEST_BASIC_INFO.buy_add_amt_pa
  is '׷���깺��ͽ��';
comment on column DEMO_INVEST_BASIC_INFO.sell_value
  is '���м۸�';
comment on column DEMO_INVEST_BASIC_INFO.prod_share_type
  is '��Ʒ�ֺ췽ʽ';
-- Create/Recreate primary, unique and foreign key constraints 
alter table DEMO_INVEST_BASIC_INFO
  add constraint PK_DEMO_INVEST_BASIC_INFO primary key (INVEST_ID)
  using index ;
-- Create/Recreate indexes 
create unique index IDX_DEMO_INVEST_BASIC_INFO_1 on DEMO_INVEST_BASIC_INFO (FPPS_INVEST_ID);
-- Create table
create table DEMO_INVEST_INFO
(
  plan_id            CHAR(6),
  invest_id          CHAR(6) not null,
  invest_name        VARCHAR2(100)
);
-- Add comments to the table 
comment on table DEMO_INVEST_INFO
  is '�����Ϣ��';
-- Add comments to the columns 
comment on column DEMO_INVEST_INFO.plan_id
  is '�ƻ�����';
comment on column DEMO_INVEST_INFO.invest_id
  is 'Ͷ����ϴ���';
comment on column DEMO_INVEST_INFO.invest_name
  is 'Ͷ���������';
-- Create/Recreate primary, unique and foreign key constraints 
alter table DEMO_INVEST_INFO
  add constraint PK_DEMO_INVEST_INFO primary key (INVEST_ID)
  using index ;
-- Create/Recreate indexes 
create index IDX_DEMO_INVEST_INFO_1 on DEMO_INVEST_INFO (PLAN_ID);

CREATE OR REPLACE VIEW V_INVEST_OP_CONTROL AS
SELECT invest_id,
       op_type,
       term_no,
       invest_time,
       lcr_way,
       unit_value_date,
       CASE
           WHEN op_type IN (1, 2) THEN
            invest_time
           ELSE
            to_char(to_date(invest_time, 'yyyy-mm-dd') + 1, 'yyyy-mm-dd')
       END demo_invest_time
  FROM demo_invest_op_control
 WHERE op_type IN (1, 2, 3, 4, 5);

-- Create table
create table DEMO_CO_INFO
(
  co_id                  CHAR(13) not null,
  sup_co                 CHAR(13),
  plan_id                CHAR(6),
  co_fname               VARCHAR2(120)
);
-- Add comments to the table 
comment on table DEMO_CO_INFO
  is '��ҵ�˻���Ϣ��';
-- Add comments to the columns 
comment on column DEMO_CO_INFO.co_id
  is '��ҵ�˻����';
comment on column DEMO_CO_INFO.sup_co
  is '�ϼ��˻����';
comment on column DEMO_CO_INFO.plan_id
  is '�ƻ����';
comment on column DEMO_CO_INFO.co_fname
  is '��ҵȫ��';

-- Create/Recreate primary, unique and foreign key constraints 
alter table DEMO_CO_INFO
  add constraint PK_DEMO_CO_INFO primary key (CO_ID)
  using index ;
-- Create/Recreate indexes 
create index IDX_DEMO_CO_INFO_1 on DEMO_CO_INFO (SUP_CO, PLAN_ID);
create index IDX_DEMO_CO_INFO_2 on DEMO_CO_INFO (PLAN_ID);

-- Create table
create table DEMO_EMP_INFO
(
  emp_client_id         CHAR(10) not null,
  emp_id                CHAR(10) not null,
  co_id                 CHAR(13) not null,
  acct_state            NUMBER(2) not null
);
-- Add comments to the table 
comment on table DEMO_EMP_INFO
  is '�����˻���Ϣ��';
-- Add comments to the columns 
comment on column DEMO_EMP_INFO.emp_client_id
  is '������Ϣ����';
comment on column DEMO_EMP_INFO.emp_id
  is '�����˻�����';
comment on column DEMO_EMP_INFO.co_id
  is '��ҵ�˻�����';
comment on column DEMO_EMP_INFO.acct_state
  is '�˻�״̬';
-- Create/Recreate primary, unique and foreign key constraints 
alter table DEMO_EMP_INFO
  add constraint PK_DEMO_EMP_INFO primary key (EMP_ID)
  using index ;
create index IDX_DEMO_EMP_INFO_3 on DEMO_EMP_INFO (CO_ID);

-- Create table
create global temporary table DEMO_OP_CO
(
  co_id    CHAR(13) not null,
  l1_co_id CHAR(13),
  sys_time DATE,
  plan_id  CHAR(6),
  op_date  VARCHAR2(10)
)
on commit preserve rows;
-- Add comments to the table 
comment on table DEMO_OP_CO
  is '��ǰ��ҵ�¼����Բ�������ҵ';
-- Add comments to the columns 
comment on column DEMO_OP_CO.co_id
  is '��ҵ����';
comment on column DEMO_OP_CO.l1_co_id
  is 'һ����ҵ����';
comment on column DEMO_OP_CO.sys_time
  is 'ϵͳʱ��';
comment on column DEMO_OP_CO.plan_id
  is '�ƻ�����';
comment on column DEMO_OP_CO.op_date
  is '����ʱ��';

-- Create table
create table DEMO_EMP_INVEST_TERM
(
  emp_id       CHAR(10) not null,
  co_id        CHAR(13) not null,
  subject_type CHAR(6) not null,
  invest_id    CHAR(6) not null,
  invest_time  CHAR(10) not null,
  amt          NUMBER(17,2) not null,
  update_time  DATE
);
-- Add comments to the table 
comment on table DEMO_EMP_INVEST_TERM
  is '���˴�������Ͷ���ʲ�����';
-- Add comments to the columns 
comment on column DEMO_EMP_INVEST_TERM.emp_id
  is '�����˻�����';
comment on column DEMO_EMP_INVEST_TERM.co_id
  is '������ҵ����';
comment on column DEMO_EMP_INVEST_TERM.subject_type
  is '��Ŀ';
comment on column DEMO_EMP_INVEST_TERM.invest_id
  is 'Ͷ����ϱ���';
comment on column DEMO_EMP_INVEST_TERM.invest_time
  is '����ȷ����������';
comment on column DEMO_EMP_INVEST_TERM.amt
  is 'Ͷ���ܽ��';
comment on column DEMO_EMP_INVEST_TERM.update_time
  is '�������ϵͳʱ��';
-- Create/Recreate primary, unique and foreign key constraints 
alter table DEMO_EMP_INVEST_TERM
  add constraint PK_DEMO_EMP_INVEST_TERM primary key (EMP_ID, SUBJECT_TYPE, INVEST_ID, INVEST_TIME)
  using index ;
-- Create/Recreate indexes 
create index IDX_DEMO_EMP_INVEST_TERM_1 on DEMO_EMP_INVEST_TERM (CO_ID);

-- Create table
create table DEMO_CO_INVEST_TERM
(
  co_id        CHAR(13) not null,
  subject_type CHAR(6) not null,
  invest_id    CHAR(6) not null,
  invest_time  CHAR(10) not null,
  amt          NUMBER(17,2) not null,
  update_time  DATE
);
-- Add comments to the table 
comment on table DEMO_CO_INVEST_TERM
  is '��ҵ��������Ͷ���ʲ�����';
-- Add comments to the columns 
comment on column DEMO_CO_INVEST_TERM.co_id
  is '������ҵ����';
comment on column DEMO_CO_INVEST_TERM.subject_type
  is '��Ŀ';
comment on column DEMO_CO_INVEST_TERM.invest_id
  is 'Ͷ����ϱ���';
comment on column DEMO_CO_INVEST_TERM.invest_time
  is '����ȷ����������';
comment on column DEMO_CO_INVEST_TERM.amt
  is 'Ͷ���ܽ��';
comment on column DEMO_CO_INVEST_TERM.update_time
  is '�������ϵͳʱ��';
-- Create/Recreate primary, unique and foreign key constraints 
alter table DEMO_CO_INVEST_TERM
  add constraint PK_DEMO_CO_INVEST_TERM primary key (CO_ID, SUBJECT_TYPE, INVEST_ID, INVEST_TIME)
  using index ;

-- Create table
create table DEMO_APPL_NUM_REL
(
  co_id       CHAR(13) not null,
  invest_id   CHAR(6) not null,
  appl_num    NUMBER(17) not null,
  invest_time CHAR(10) not null,
  amt         NUMBER(17,2),
  red_amt     NUMBER(17,2) default 0
);
-- Add comments to the table 
comment on table DEMO_APPL_NUM_REL
  is '���뵥��Ź�ϵ��';
-- Add comments to the columns 
comment on column DEMO_APPL_NUM_REL.co_id
  is '��ҵ����';
comment on column DEMO_APPL_NUM_REL.invest_id
  is 'Ͷ����ϱ��';
comment on column DEMO_APPL_NUM_REL.appl_num
  is '���뵥���';
comment on column DEMO_APPL_NUM_REL.invest_time
  is '����ȷ����';
comment on column DEMO_APPL_NUM_REL.amt
  is '�ܱ���';
comment on column DEMO_APPL_NUM_REL.red_amt
  is '����ؽ��';
-- Create/Recreate primary, unique and foreign key constraints 
alter table DEMO_APPL_NUM_REL
  add constraint PK_DEMO_APPL_NUM_REL primary key (APPL_NUM)
  using index ;
-- Create/Recreate indexes 
create index IDX_DEMO_APPL_NUM_REL_1 on DEMO_APPL_NUM_REL (INVEST_ID, INVEST_TIME);
create index IDX_DEMO_APPL_NUM_REL_2 on DEMO_APPL_NUM_REL (CO_ID, INVEST_ID, INVEST_TIME);

-- Create table
create table DEMO_INVEST_UNIT_VALUE
(
  invest_id        CHAR(6) not null,
  evaluate_date    CHAR(10) not null,
  plan_id          CHAR(6),
  next_eval_date   CHAR(10),
  net_amt          NUMBER(17,2),
  net_amt_inc_rate NUMBER(7,4),
  unit_value       NUMBER(15,6),
  op_date          CHAR(10),
  eval_state_flag  NUMBER(2),
  last_set_value   NUMBER(17,2),
  is_reported      NUMBER(2) default 0,
  quotient         NUMBER(21,6)
);
-- Add comments to the table 
comment on table DEMO_INVEST_UNIT_VALUE
  is 'Ͷ����ϵ�λ��ֵ��';
-- Add comments to the columns 
comment on column DEMO_INVEST_UNIT_VALUE.invest_id
  is 'Ͷ����ϱ��';
comment on column DEMO_INVEST_UNIT_VALUE.evaluate_date
  is '��ֵ����';
comment on column DEMO_INVEST_UNIT_VALUE.plan_id
  is '�ƻ�����';
comment on column DEMO_INVEST_UNIT_VALUE.next_eval_date
  is '�´ι�ֵ����';
comment on column DEMO_INVEST_UNIT_VALUE.net_amt
  is '����Ʋ���ֵ';
comment on column DEMO_INVEST_UNIT_VALUE.net_amt_inc_rate
  is '��ֵ������';
comment on column DEMO_INVEST_UNIT_VALUE.unit_value
  is 'ÿ�ݽ��';
comment on column DEMO_INVEST_UNIT_VALUE.op_date
  is '������';
comment on column DEMO_INVEST_UNIT_VALUE.eval_state_flag
  is '�����յ�ǰ״̬��־';
comment on column DEMO_INVEST_UNIT_VALUE.last_set_value
  is '���»�����ĩ�ʲ����';
comment on column DEMO_INVEST_UNIT_VALUE.is_reported
  is '�Ƿ������ɼ�ؽ�����ܱ�0.δ���ɣ�1.�����ɣ�';
comment on column DEMO_INVEST_UNIT_VALUE.quotient
  is '�ʲ��ݶ�';
-- Create/Recreate primary, unique and foreign key constraints 
alter table DEMO_INVEST_UNIT_VALUE
  add constraint PK_DEMO_INVEST_UNIT_VALUE primary key (INVEST_ID, EVALUATE_DATE)
  using index ;
-- Create/Recreate indexes 
create index IDX_DEMO_INVEST_UNIT_VALUE_1 on DEMO_INVEST_UNIT_VALUE (PLAN_ID, EVAL_STATE_FLAG);
create index IDX_DEMO_INVEST_UNIT_VALUE_2 on DEMO_INVEST_UNIT_VALUE (INVEST_ID, OP_DATE);
create index IDX_DEMO_INVEST_UNIT_VALUE_3 on DEMO_INVEST_UNIT_VALUE (INVEST_ID, EVAL_STATE_FLAG);

-- Create table
create table DEMO_EMP_INVEST
(
  emp_id       CHAR(10) not null,
  co_id        CHAR(13) not null,
  subject_type CHAR(6) not null,
  invest_id    VARCHAR2(10) not null,
  amt          NUMBER(17,2) not null,
  quotient     NUMBER(21,6),
  set_value    NUMBER(17,2),
  update_time  DATE
);
-- Add comments to the table 
comment on table DEMO_EMP_INVEST
  is '�����˻�Ͷ���ʲ���';
-- Add comments to the columns 
comment on column DEMO_EMP_INVEST.emp_id
  is '�����˻�����';
comment on column DEMO_EMP_INVEST.co_id
  is '������ҵ����';
comment on column DEMO_EMP_INVEST.subject_type
  is '��Ŀ';
comment on column DEMO_EMP_INVEST.invest_id
  is 'Ͷ����ϱ���';
comment on column DEMO_EMP_INVEST.amt
  is 'Ͷ���ܽ��';
comment on column DEMO_EMP_INVEST.quotient
  is '�ۼƷݶ�';
comment on column DEMO_EMP_INVEST.set_value
  is '��ֵ';
comment on column DEMO_EMP_INVEST.update_time
  is '�������ϵͳʱ��';
-- Create/Recreate primary, unique and foreign key constraints 
alter table DEMO_EMP_INVEST
  add constraint PK_DEMO_EMP_INVEST primary key (EMP_ID, SUBJECT_TYPE, INVEST_ID)
  using index;
-- Create/Recreate indexes 
create index IDX_DEMO_EMP_INVEST_1 on DEMO_EMP_INVEST (CO_ID);

-- Create table
create table DEMO_CO_INVEST
(
  co_id        CHAR(13) not null,
  subject_type CHAR(6) not null,
  invest_id    CHAR(6) not null,
  amt          NUMBER(17,2) not null,
  quotient     NUMBER(21,6),
  set_value    NUMBER(17,2),
  update_time  DATE
)
tablespace OAM_MAIN_DATA;
-- Add comments to the table 
comment on table DEMO_CO_INVEST
  is '��ҵͶ���ʲ���';
-- Add comments to the columns 
comment on column DEMO_CO_INVEST.co_id
  is '��ҵ����';
comment on column DEMO_CO_INVEST.subject_type
  is '��Ŀ';
comment on column DEMO_CO_INVEST.invest_id
  is 'Ͷ����ϱ���';
comment on column DEMO_CO_INVEST.amt
  is 'Ͷ���ܽ��';
comment on column DEMO_CO_INVEST.quotient
  is '�ۼƷݶ�';
comment on column DEMO_CO_INVEST.set_value
  is '��ֵ';
comment on column DEMO_CO_INVEST.update_time
  is '�������ϵͳʱ��';
-- Create/Recreate primary, unique and foreign key constraints 
alter table DEMO_CO_INVEST
  add constraint PK_DEMO_CO_INVEST primary key (CO_ID, SUBJECT_TYPE, INVEST_ID)
  using index;
-- Create/Recreate indexes 
create index IDX_DEMO_CO_INVEST_1 on DEMO_CO_INVEST (TO_CHAR(UPDATE_TIME,'yyyy-mm-dd'));

