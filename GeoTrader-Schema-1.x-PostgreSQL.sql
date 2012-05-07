-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Mon May  7 16:47:54 2012
-- 
--
-- Table: achievements
--
DROP TABLE "achievements" CASCADE;
CREATE TABLE "achievements" (
  "id" serial NOT NULL,
  "name" character varying(255) NOT NULL,
  "details" character varying(1024) NOT NULL,
  "difficulty" integer NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: cards
--
DROP TABLE "cards" CASCADE;
CREATE TABLE "cards" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "photo" text,
  "details" text,
  "origin_point_id" integer,
  "max_available" integer DEFAULT 10 NOT NULL,
  PRIMARY KEY ("id")
);

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
-- Table: points
--
DROP TABLE "points" CASCADE;
CREATE TABLE "points" (
  "id" serial NOT NULL,
  "osm_id" integer,
  "place_id" integer,
  "location_lat" numeric NOT NULL,
  "location_lon" numeric NOT NULL,
  "is_visible" integer DEFAULT 1 NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "osmnode" UNIQUE ("osm_id")
);
CREATE INDEX "points_idx_place_id" on "points" ("place_id");

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
-- Table: achievement_cards
--
DROP TABLE "achievement_cards" CASCADE;
CREATE TABLE "achievement_cards" (
  "achievement_id" integer NOT NULL,
  "card_id" integer NOT NULL,
  PRIMARY KEY ("achievement_id", "card_id")
);
CREATE INDEX "achievement_cards_idx_achievement_id" on "achievement_cards" ("achievement_id");
CREATE INDEX "achievement_cards_idx_card_id" on "achievement_cards" ("card_id");

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
-- Table: card_instances
--
DROP TABLE "card_instances" CASCADE;
CREATE TABLE "card_instances" (
  "card_id" integer NOT NULL,
  "point_id" integer NOT NULL,
  PRIMARY KEY ("card_id", "point_id")
);
CREATE INDEX "card_instances_idx_card_id" on "card_instances" ("card_id");
CREATE INDEX "card_instances_idx_point_id" on "card_instances" ("point_id");

--
-- Foreign Key Definitions
--

ALTER TABLE "points" ADD FOREIGN KEY ("place_id")
  REFERENCES "places" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "tags" ADD FOREIGN KEY ("card_id")
  REFERENCES "cards" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "user_latlon" ADD FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE DEFERRABLE;

ALTER TABLE "achievement_cards" ADD FOREIGN KEY ("achievement_id")
  REFERENCES "achievements" ("id") DEFERRABLE;

ALTER TABLE "achievement_cards" ADD FOREIGN KEY ("card_id")
  REFERENCES "cards" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "user_cards" ADD FOREIGN KEY ("card_id")
  REFERENCES "cards" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "user_cards" ADD FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "card_instances" ADD FOREIGN KEY ("card_id")
  REFERENCES "cards" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "card_instances" ADD FOREIGN KEY ("point_id")
  REFERENCES "points" ("id") DEFERRABLE;


