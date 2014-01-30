create or replace type invest_appl as object
(
  co_id       varchar2(13),
  invest_time varchar2(10),
  appl_num    NUMBER(17),
  member function FUNC_GET_REDABLE_APPL_AMT(I_AMT         IN NUMBER,
                                            I_REDABLE_AMT IN NUMBER)
    RETURN NUMBER,
  member PROCEDURE PROC_DEAL_POP_EX_TERM_TO_APPL(I_EMP_ID                 IN VARCHAR2,
                                                 I_SUBJECT_TYPE           IN VARCHAR2,
                                                 I_DEAL_POP_DONE_APPL_AMT IN NUMBER)

)
/
create or replace type body invest_appl is
  member function FUNC_GET_REDABLE_APPL_AMT(I_AMT         IN NUMBER,
                                            I_REDABLE_AMT IN NUMBER)
    RETURN NUMBER IS
    V_REDABLE_APPL_AMT NUMBER(17, 2);
  BEGIN
    SELECT I_AMT - NVL(I_REDABLE_AMT, 0) - NVL(SUM(T3.AMT), 0)
      INTO V_REDABLE_APPL_AMT
      FROM DEMO_INVEST_POP_RESULT_TMP T3
     WHERE T3.CO_ID = self.CO_ID
       AND T3.INVEST_TIME = self.INVEST_TIME
       AND T3.YAPPL_NUM = self.APPL_NUM;
    RETURN V_REDABLE_APPL_AMT;
  END;
  member PROCEDURE PROC_DEAL_POP_EX_TERM_TO_APPL(I_EMP_ID                 IN VARCHAR2,
                                                 I_SUBJECT_TYPE           IN VARCHAR2,
                                                 I_DEAL_POP_DONE_APPL_AMT IN NUMBER) IS
  
  BEGIN
    INSERT INTO DEMO_INVEST_POP_RESULT_TMP
      (EMP_ID, CO_ID, SUBJECT_TYPE, INVEST_TIME, AMT, QUOTIENT, YAPPL_NUM)
    VALUES
      (I_EMP_ID,
       self.CO_ID,
       I_SUBJECT_TYPE,
       self.INVEST_TIME,
       I_DEAL_POP_DONE_APPL_AMT,
       I_DEAL_POP_DONE_APPL_AMT,
       self.APPL_NUM);
  
  END;

end;
/
