-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Sat Apr 28 12:19:25 2012
-- 
--
-- Table: places
--
DROP TABLE "places" CASCADE;
CREATE TABLE "places" (
  "id" serial NOT NULL,
  "village" text,
  "town" text,
  "city" text,
  "county" text,
  "country_code" text NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: users
--
DROP TABLE "users" CASCADE;
CREATE TABLE "users" (
  "id" serial NOT NULL,
  "username" character varying(50) NOT NULL,
  "password" character varying(255) NOT NULL,
  "display_name" character varying(50) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "username" UNIQUE ("username")
);

--
-- Table: cards
--
DROP TABLE "cards" CASCADE;
CREATE TABLE "cards" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "osm_id" integer,
  "place_id" integer,
  "photo" text,
  "details" text,
  "location_lat" numeric NOT NULL,
  "location_lon" numeric NOT NULL,
  "max_available" integer DEFAULT 10 NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "cards_idx_place_id" on "cards" ("place_id");

--
-- Table: user_latlon
--
DROP TABLE "user_latlon" CASCADE;
CREATE TABLE "user_latlon" (
  "user_id" integer NOT NULL,
  "latitude" numeric NOT NULL,
  "longitude" numeric NOT NULL,
  PRIMARY KEY ("user_id")
);

--
-- Table: tags
--
DROP TABLE "tags" CASCADE;
CREATE TABLE "tags" (
  "card_id" integer NOT NULL,
  "key" text NOT NULL,
  "value" text NOT NULL,
  PRIMARY KEY ("card_id", "key")
);
CREATE INDEX "tags_idx_card_id" on "tags" ("card_id");

--
-- Table: user_cards
--
DROP TABLE "user_cards" CASCADE;
CREATE TABLE "user_cards" (
  "user_id" serial NOT NULL,
  "card_id" character varying(50) NOT NULL,
  PRIMARY KEY ("user_id", "card_id")
);
CREATE INDEX "user_cards_idx_card_id" on "user_cards" ("card_id");
CREATE INDEX "user_cards_idx_user_id" on "user_cards" ("user_id");

--
-- Foreign Key Definitions
--

ALTER TABLE "cards" ADD FOREIGN KEY ("place_id")
  REFERENCES "places" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "user_latlon" ADD FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE DEFERRABLE;

ALTER TABLE "tags" ADD FOREIGN KEY ("card_id")
  REFERENCES "cards" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "user_cards" ADD FOREIGN KEY ("card_id")
  REFERENCES "cards" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "user_cards" ADD FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;


