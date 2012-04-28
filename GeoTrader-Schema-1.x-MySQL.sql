-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Sat Apr 28 12:19:25 2012
-- 
SET foreign_key_checks=0;

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

DROP TABLE IF EXISTS `cards`;

--
-- Table: `cards`
--
CREATE TABLE `cards` (
  `id` integer NOT NULL auto_increment,
  `name` TINYTEXT NOT NULL,
  `osm_id` integer,
  `place_id` integer,
  `photo` TINYTEXT,
  `details` text,
  `location_lat` float NOT NULL,
  `location_lon` float NOT NULL,
  `max_available` integer NOT NULL DEFAULT 10,
  INDEX `cards_idx_place_id` (`place_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `cards_fk_place_id` FOREIGN KEY (`place_id`) REFERENCES `places` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
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

SET foreign_key_checks=1;


