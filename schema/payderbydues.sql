-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Tue Oct  6 17:08:28 2015
-- 
--
-- Table: feeschedule
--
CREATE TABLE "feeschedule" (
  "id" serial NOT NULL,
  "name" text,
  "leagueid" integer,
  "value" integer,
  CONSTRAINT "pk_feeschedule" PRIMARY KEY ("id")
);

--
-- Table: invoiceitem
--
CREATE TABLE "invoiceitem" (
  "id" serial NOT NULL,
  "value" integer,
  "stripe_invoiceitemid" character varying(40),
  "leaguememberid" integer,
  CONSTRAINT "pk_invoiceitem" PRIMARY KEY ("id")
);

--
-- Table: league
--
CREATE TABLE "league" (
  "id" serial NOT NULL,
  "name" text,
  CONSTRAINT "pk_league" PRIMARY KEY ("id")
);

--
-- Table: leaguestripedata
--
CREATE TABLE "leaguestripedata" (
  "id" serial NOT NULL,
  "leagueid" integer,
  "stripe_account" character varying(40),
  "stripe_publickey" character varying(40),
  "stripe_secretkey" character varying(40),
  CONSTRAINT "pk_leaguestripedata" PRIMARY KEY ("id")
);

--
-- Table: leaguemember
--
CREATE TABLE "leaguemember" (
  "id" serial NOT NULL,
  "leagueid" integer,
  "userid" integer,
  CONSTRAINT "pk_leaguemember" PRIMARY KEY ("id")
);

--
-- Table: role
--
CREATE TABLE "role" (
  "id" serial NOT NULL,
  "name" text,
  CONSTRAINT "pk_role" PRIMARY KEY ("id")
);

--
-- Table: leaguememberrole
--
CREATE TABLE "leaguememberrole" (
  "id" serial NOT NULL,
  "leaguememberid" integer,
  "roleid" integer,
  CONSTRAINT "pk_leaguememberrole" PRIMARY KEY ("id")
);

--
-- Table: payment
--
CREATE TABLE "payment" (
  "id" serial NOT NULL,
  "leaguememberid" integer,
  "value" integer,
  "stripe_chargeid" character varying(40),
  CONSTRAINT "pk_payment" PRIMARY KEY ("id")
);

--
-- Table: users
--
CREATE TABLE "users" (
  "id" serial NOT NULL,
  "email" character varying(100),
  "legalname" character varying(100),
  "derbyname" character varying(100),
  "password" character varying(64),
  CONSTRAINT "pk_users" PRIMARY KEY ("id")
);

--
-- Table: tokens
--
CREATE TABLE "tokens" (
  "id" serial NOT NULL,
  "value" character varying(64),
  "expires" timestamp without time zone,
  "userid" integer,
  CONSTRAINT "pk_tokens" PRIMARY KEY ("id")
);

--
-- Foreign Key Definitions
--

ALTER TABLE "feeschedule" ADD CONSTRAINT "fk_leagueid" FOREIGN KEY ("leagueid")
  REFERENCES "league" ("id") ON DELETE cascade DEFERRABLE;

ALTER TABLE "invoiceitem" ADD CONSTRAINT "fk_leaguememberid" FOREIGN KEY ("leaguememberid")
  REFERENCES "leaguemember" ("id") ON DELETE cascade DEFERRABLE;

ALTER TABLE "leaguestripedata" ADD CONSTRAINT "fk_leagueid" FOREIGN KEY ("leagueid")
  REFERENCES "league" ("id") ON DELETE cascade DEFERRABLE;

ALTER TABLE "leaguemember" ADD CONSTRAINT "fk_leagueid" FOREIGN KEY ("leagueid")
  REFERENCES "league" ("id") ON DELETE cascade DEFERRABLE;

ALTER TABLE "leaguemember" ADD CONSTRAINT "fk_userid" FOREIGN KEY ("userid")
  REFERENCES "users" ("id") ON DELETE cascade DEFERRABLE;

ALTER TABLE "leaguememberrole" ADD CONSTRAINT "fk_leaguememberid" FOREIGN KEY ("leaguememberid")
  REFERENCES "leaguemember" ("id") ON DELETE cascade DEFERRABLE;

ALTER TABLE "leaguememberrole" ADD CONSTRAINT "fk_roleid" FOREIGN KEY ("roleid")
  REFERENCES "role" ("id") ON DELETE cascade DEFERRABLE;

ALTER TABLE "payment" ADD CONSTRAINT "fk_leaguememberid" FOREIGN KEY ("leaguememberid")
  REFERENCES "leaguemember" ("id") ON DELETE cascade DEFERRABLE;

ALTER TABLE "tokens" ADD CONSTRAINT "fk_userid" FOREIGN KEY ("userid")
  REFERENCES "users" ("id") ON DELETE cascade DEFERRABLE;

