-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Mon May  7 16:47:54 2012
-- 

BEGIN TRANSACTION;

--
-- Table: achievements
--
DROP TABLE achievements;

CREATE TABLE achievements (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(255) NOT NULL,
  details varchar(1024) NOT NULL,
  difficulty integer NOT NULL
);

--
-- Table: cards
--
DROP TABLE cards;

CREATE TABLE cards (
  id INTEGER PRIMARY KEY NOT NULL,
  name TINYTEXT NOT NULL,
  photo TINYTEXT,
  details TEXT,
  origin_point_id integer,
  max_available integer NOT NULL DEFAULT 10
);

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
-- Table: points
--
DROP TABLE points;

CREATE TABLE points (
  id INTEGER PRIMARY KEY NOT NULL,
  osm_id integer,
  place_id integer,
  location_lat float NOT NULL,
  location_lon float NOT NULL,
  is_visible integer NOT NULL DEFAULT 1,
  FOREIGN KEY(place_id) REFERENCES places(id)
);

CREATE INDEX points_idx_place_id ON points (place_id);

CREATE UNIQUE INDEX osmnode ON points (osm_id);

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
-- Table: achievement_cards
--
DROP TABLE achievement_cards;

CREATE TABLE achievement_cards (
  achievement_id integer NOT NULL,
  card_id integer NOT NULL,
  PRIMARY KEY (achievement_id, card_id),
  FOREIGN KEY(achievement_id) REFERENCES achievements(id),
  FOREIGN KEY(card_id) REFERENCES cards(id)
);

CREATE INDEX achievement_cards_idx_achievement_id ON achievement_cards (achievement_id);

CREATE INDEX achievement_cards_idx_card_id ON achievement_cards (card_id);

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

--
-- Table: card_instances
--
DROP TABLE card_instances;

CREATE TABLE card_instances (
  card_id integer NOT NULL,
  point_id integer NOT NULL,
  PRIMARY KEY (card_id, point_id),
  FOREIGN KEY(card_id) REFERENCES cards(id),
  FOREIGN KEY(point_id) REFERENCES points(id)
);

CREATE INDEX card_instances_idx_card_id ON card_instances (card_id);

CREATE INDEX card_instances_idx_point_id ON card_instances (point_id);

COMMIT;

