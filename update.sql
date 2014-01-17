CREATE OR REPLACE VIEW V_EMP_CO_INVEST_ACCT AS
SELECT EMP_ID,
       CO_ID,
       INVEST_ID,
       SUBJECT_TYPE,
       QUOTIENT,
       AMT
        FROM DEMO_EMP_INVEST
       WHERE quotient > 0
UNION
SELECT 'FFFFFFFFFF'EMP_ID,
       CO_ID,
       INVEST_ID,
       SUBJECT_TYPE,
       QUOTIENT,
       AMT
  FROM DEMO_CO_INVEST
 WHERE quotient > 0;

alter table DEMO_INVEST_POP_TMP add quotient_remain NUMBER(17,2);
comment on column DEMO_INVEST_POP_TMP.quotient_remain
  is '剩余份额';

-- Drop columns 
alter table DEMO_INVEST_POP_TMP drop column amt_remain;

create OR REPLACE view v_invest_term_acct_emp_and_co as
SELECT INVEST_TIME, CO_ID, invest_id,emp_id,subject_type,amt
  FROM DEMO_EMP_INVEST_TERM
 WHERE AMT > 0
UNION
SELECT INVEST_TIME, CO_ID, invest_id,'FFFFFFFFFF' emp_id, subject_type,amt
  FROM DEMO_co_INVEST_TERM
 WHERE AMT > 0
   and subject_type >= '302001';