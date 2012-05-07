-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Mon May  7 16:47:54 2012
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS `achievements`;

--
-- Table: `achievements`
--
CREATE TABLE `achievements` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `details` text NOT NULL,
  `difficulty` integer NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `cards`;

--
-- Table: `cards`
--
CREATE TABLE `cards` (
  `id` integer NOT NULL auto_increment,
  `name` TINYTEXT NOT NULL,
  `photo` TINYTEXT,
  `details` text,
  `origin_point_id` integer,
  `max_available` integer NOT NULL DEFAULT 10,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `places`;

--
-- Table: `places`
--
CREATE TABLE `places` (
  `id` integer NOT NULL auto_increment,
  `village` TINYTEXT,
  `town` TINYTEXT,
  `city` TINYTEXT,
  `county` TINYTEXT,
  `country_code` TINYTEXT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `users`;

--
-- Table: `users`
--
CREATE TABLE `users` (
  `id` integer NOT NULL auto_increment,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `display_name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE `username` (`username`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `points`;

--
-- Table: `points`
--
CREATE TABLE `points` (
  `id` integer NOT NULL auto_increment,
  `osm_id` integer,
  `place_id` integer,
  `location_lat` float NOT NULL,
  `location_lon` float NOT NULL,
  `is_visible` integer NOT NULL DEFAULT 1,
  INDEX `points_idx_place_id` (`place_id`),
  PRIMARY KEY (`id`),
  UNIQUE `osmnode` (`osm_id`),
  CONSTRAINT `points_fk_place_id` FOREIGN KEY (`place_id`) REFERENCES `places` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `tags`;

--
-- Table: `tags`
--
CREATE TABLE `tags` (
  `card_id` integer NOT NULL,
  `key` TINYTEXT NOT NULL,
  `value` TINYTEXT NOT NULL,
  INDEX `tags_idx_card_id` (`card_id`),
  PRIMARY KEY (`card_id`, `key`),
  CONSTRAINT `tags_fk_card_id` FOREIGN KEY (`card_id`) REFERENCES `cards` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `user_latlon`;

--
-- Table: `user_latlon`
--
CREATE TABLE `user_latlon` (
  `user_id` integer NOT NULL,
  `latitude` float NOT NULL,
  `longitude` float NOT NULL,
  INDEX (`user_id`),
  PRIMARY KEY (`user_id`),
  CONSTRAINT `user_latlon_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `achievement_cards`;

--
-- Table: `achievement_cards`
--
CREATE TABLE `achievement_cards` (
  `achievement_id` integer NOT NULL,
  `card_id` integer NOT NULL,
  INDEX `achievement_cards_idx_achievement_id` (`achievement_id`),
  INDEX `achievement_cards_idx_card_id` (`card_id`),
  PRIMARY KEY (`achievement_id`, `card_id`),
  CONSTRAINT `achievement_cards_fk_achievement_id` FOREIGN KEY (`achievement_id`) REFERENCES `achievements` (`id`),
  CONSTRAINT `achievement_cards_fk_card_id` FOREIGN KEY (`card_id`) REFERENCES `cards` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `user_cards`;

--
-- Table: `user_cards`
--
CREATE TABLE `user_cards` (
  `user_id` integer NOT NULL auto_increment,
  `card_id` varchar(50) NOT NULL,
  INDEX `user_cards_idx_card_id` (`card_id`),
  INDEX `user_cards_idx_user_id` (`user_id`),
  PRIMARY KEY (`user_id`, `card_id`),
  CONSTRAINT `user_cards_fk_card_id` FOREIGN KEY (`card_id`) REFERENCES `cards` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `user_cards_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `card_instances`;

--
-- Table: `card_instances`
--
CREATE TABLE `card_instances` (
  `card_id` integer NOT NULL,
  `point_id` integer NOT NULL,
  INDEX `card_instances_idx_card_id` (`card_id`),
  INDEX `card_instances_idx_point_id` (`point_id`),
  PRIMARY KEY (`card_id`, `point_id`),
  CONSTRAINT `card_instances_fk_card_id` FOREIGN KEY (`card_id`) REFERENCES `cards` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `card_instances_fk_point_id` FOREIGN KEY (`point_id`) REFERENCES `points` (`id`)
) ENGINE=InnoDB;

SET foreign_key_checks=1;


