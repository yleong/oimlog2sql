create table "LOGLINE"
(
	"LOGLINE_KEY" NUMBER(19, 0) NOT NULL ENABLE,
	"LOGLINE_DATE" TIMESTAMP,
	"LOGLINE_SERVER" VARCHAR2(20 CHAR),
	"LOGLINE_LEVEL" VARCHAR2(20 CHAR),
	"LOGLINE_ERRCODE" VARCHAR2(20 CHAR),
	"LOGLINE_SCOPE" VARCHAR2(100 CHAR),
	"LOGLINE_TID" VARCHAR2(150 CHAR),
	"LOGLINE_UID" VARCHAR(30 CHAR),
	"LOGLINE_ECID" VARCHAR(100 CHAR),
	"LOGLINE_MESSAGES" CLOB
)
create index "IDX_LOGLINE_KEY" on "LOGLINE"
(
	"LOGLINE_KEY"
)
create index "IDX_LOGLINE_LEVEL" on "LOGLINE"
(
	"LOGLINE_LEVEL"
)
create index "IDX_LOGLINE_ECID" on "LOGLINE"
(
	"LOGLINE_ECID"
)
create index "IDX_LOGLINE_DATE" on "LOGLINE"
(
	"LOGLINE_DATE"
)

alter table LOGLINE add
(
	constraint logline_pk PRIMARY KEY(LOGLINE_KEY)
);

create sequence logline_seq;

create or replace trigger logline_bir
before insert on LOGLINE
for each row
begin
	select LOGLINE_SEQ.NEXTVAL
	into :new.LOGLINE_KEY
	from dual;
end;

drop table logline
drop sequence logline_seq

