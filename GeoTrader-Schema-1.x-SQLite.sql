-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Sat Apr 28 12:19:25 2012
-- 

BEGIN TRANSACTION;

--
-- Table: places
--
DROP TABLE places;

CREATE TABLE places (
  id INTEGER PRIMARY KEY NOT NULL,
  village TINYTEXT,
  town TINYTEXT,
  city TINYTEXT,
  county TINYTEXT,
  country_code TINYTEXT NOT NULL
);

--
-- Table: users
--
DROP TABLE users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY NOT NULL,
  username varchar(50) NOT NULL,
  password varchar(255) NOT NULL,
  display_name varchar(50) NOT NULL
);

CREATE UNIQUE INDEX username ON users (username);

--
-- Table: cards
--
DROP TABLE cards;

CREATE TABLE cards (
  id INTEGER PRIMARY KEY NOT NULL,
  name TINYTEXT NOT NULL,
  osm_id integer,
  place_id integer,
  photo TINYTEXT,
  details TEXT,
  location_lat float NOT NULL,
  location_lon float NOT NULL,
  max_available integer NOT NULL DEFAULT 10,
  FOREIGN KEY(place_id) REFERENCES places(id)
);

CREATE INDEX cards_idx_place_id ON cards (place_id);

--
-- Table: user_latlon
--
DROP TABLE user_latlon;

CREATE TABLE user_latlon (
  user_id INTEGER PRIMARY KEY NOT NULL,
  latitude float NOT NULL,
  longitude float NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id)
);

--
-- Table: tags
--
DROP TABLE tags;

CREATE TABLE tags (
  card_id integer NOT NULL,
  key TINYTEXT NOT NULL,
  value TINYTEXT NOT NULL,
  PRIMARY KEY (card_id, key),
  FOREIGN KEY(card_id) REFERENCES cards(id)
);

CREATE INDEX tags_idx_card_id ON tags (card_id);

--
-- Table: user_cards
--
DROP TABLE user_cards;

CREATE TABLE user_cards (
  user_id integer NOT NULL,
  card_id varchar(50) NOT NULL,
  PRIMARY KEY (user_id, card_id),
  FOREIGN KEY(card_id) REFERENCES cards(id),
  FOREIGN KEY(user_id) REFERENCES users(id)
);

CREATE INDEX user_cards_idx_card_id ON user_cards (card_id);

CREATE INDEX user_cards_idx_user_id ON user_cards (user_id);

COMMIT;

