/*
Navicat MySQL Data Transfer

Source Server         : Local MySQL
Source Server Version : 50621
Source Host           : 127.0.0.1:3306
Source Database       : surfline

Target Server Type    : MYSQL
Target Server Version : 50621
File Encoding         : 65001

Date: 2015-01-02 21:05:45
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for gmod_admins
-- ----------------------------
DROP TABLE IF EXISTS `gmod_admins`;
CREATE TABLE `gmod_admins` (
  `nID` int(11) NOT NULL AUTO_INCREMENT,
  `szSteam` varchar(255) NOT NULL,
  `nLevel` int(11) NOT NULL DEFAULT '0',
  `nType` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`nID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Records of gmod_admins
-- ----------------------------
INSERT INTO `gmod_admins` VALUES ('1', 'STEAM_0:0:OWNERSTEAM', '64', '0');
INSERT INTO `gmod_admins` VALUES ('2', 'STEAM_0:0:DEVELOPERSTEAM', '32', '0');
INSERT INTO `gmod_admins` VALUES ('3', 'STEAM_0:0:SUPERSTEAM', '16', '0');
INSERT INTO `gmod_admins` VALUES ('4', 'STEAM_0:0:ADMINSTEAM', '8', '0');
INSERT INTO `gmod_admins` VALUES ('5', 'STEAM_0:0:MODERATORSTEAM', '4', '0');

-- ----------------------------
-- Table structure for gmod_bans
-- ----------------------------
DROP TABLE IF EXISTS `gmod_bans`;
CREATE TABLE `gmod_bans` (
  `nID` int(11) NOT NULL AUTO_INCREMENT,
  `szUserSteam` varchar(255) NOT NULL,
  `szUserName` varchar(255) DEFAULT NULL,
  `nStart` bigint(20) NOT NULL,
  `nLength` int(11) NOT NULL,
  `szReason` varchar(255) DEFAULT NULL,
  `szAdminSteam` varchar(255) NOT NULL,
  `szAdminName` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`nID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gmod_donations
-- ----------------------------
DROP TABLE IF EXISTS `gmod_donations`;
CREATE TABLE `gmod_donations` (
  `nID` int(11) NOT NULL AUTO_INCREMENT,
  `szEmail` varchar(255) NOT NULL,
  `szName` varchar(255) DEFAULT NULL,
  `szCountry` varchar(255) DEFAULT NULL,
  `nAmount` int(11) NOT NULL,
  `szSteam` varchar(255) DEFAULT NULL,
  `szDate` varchar(255) NOT NULL,
  `szStatus` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`nID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gmod_logging
-- ----------------------------
DROP TABLE IF EXISTS `gmod_logging`;
CREATE TABLE `gmod_logging` (
  `nID` int(11) NOT NULL AUTO_INCREMENT,
  `nType` int(11) NOT NULL DEFAULT '0',
  `szData` text,
  `szDate` varchar(255) DEFAULT NULL,
  `szAdminSteam` varchar(255) NOT NULL,
  `szAdminName` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`nID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gmod_notifications
-- ----------------------------
DROP TABLE IF EXISTS `gmod_notifications`;
CREATE TABLE `gmod_notifications` (
  `nID` int(11) NOT NULL AUTO_INCREMENT,
  `nType` int(11) NOT NULL DEFAULT '0',
  `nTimeout` int(11) NOT NULL DEFAULT '60',
  `szText` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`nID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Records of gmod_notifications
-- ----------------------------
-- Here, have some annoying notifications
-- No problem!
-- ----------------------------

INSERT INTO `gmod_notifications` VALUES ('1', '0', '240', 'Want a list of all available commands? Type !help.');
INSERT INTO `gmod_notifications` VALUES ('2', '0', '360', 'We have a lot of different !styles to offer. Legit now has stamina!');
INSERT INTO `gmod_notifications` VALUES ('4', '0', '240', 'Did you know you can edit your HUD position and opacity with !hudedit?');
INSERT INTO `gmod_notifications` VALUES ('5', '0', '240', 'Any type of config that improves your ability to Bhop is disallowed.');
INSERT INTO `gmod_notifications` VALUES ('6', '0', '240', 'Do you want to see the latest patch notes? Type !version');
INSERT INTO `gmod_notifications` VALUES ('7', '0', '180', 'VIPs have been updated! Have a look at !donate to see how to get it.');
INSERT INTO `gmod_notifications` VALUES ('9', '0', '180', 'Be sure to have a look at our forums. Type !forum to go there.');
INSERT INTO `gmod_notifications` VALUES ('9', '0', '180', 'Want to look at runs on YouTube? Type !youtube to check them out.');
INSERT INTO `gmod_notifications` VALUES ('11', '0', '600', 'Did you know the longest recorded flight of a chicken was 13 seconds?');
INSERT INTO `gmod_notifications` VALUES ('12', '0', '600', 'Did you know Switzerland eats the most chocolate equating to 10 kilos per person per year?');
INSERT INTO `gmod_notifications` VALUES ('13', '0', '600', 'Did you know frogs can\'t swallow with their eyes open?');
INSERT INTO `gmod_notifications` VALUES ('14', '0', '600', 'Did you know that in 1386, a pig in France was executed by public hanging for the murder of a child?');
INSERT INTO `gmod_notifications` VALUES ('15', '0', '240', 'Want to help us out with management? Go to the !forum and apply there!');
INSERT INTO `gmod_notifications` VALUES ('16', '0', '600', 'Did you know that in 1969, Rod Laver won the first and only Grand Slam of the Open Era to date?');
INSERT INTO `gmod_notifications` VALUES ('17', '0', '600', 'When two left handed people argue, who\'s right?');
INSERT INTO `gmod_notifications` VALUES ('18', '0', '600', 'Did you know that in 1788, the Austrian army attacked itself and lost 10,000 men?');
INSERT INTO `gmod_notifications` VALUES ('19', '0', '600', 'The mexican General Santa Anna had an elaborate state funeral for his amputated leg.');
INSERT INTO `gmod_notifications` VALUES ('20', '0', '600', 'The Anglo-Zanzibar war of 1896 is the shortest war on record lasting an exhausting 38 minutes');
INSERT INTO `gmod_notifications` VALUES ('21', '0', '600', 'The first bomb of the second World War dropped on Germany, and killed the only elephant in the Berlin Zoo at that time.');
INSERT INTO `gmod_notifications` VALUES ('22', '0', '600', 'The last Guillotine execution took place in Marseille, 1977.');

-- ----------------------------
-- Table structure for gmod_radio
-- ----------------------------
DROP TABLE IF EXISTS `gmod_radio`;
CREATE TABLE `gmod_radio` (
  `nID` int(11) NOT NULL AUTO_INCREMENT,
  `szUnique` varchar(255) NOT NULL,
  `nService` int(11) DEFAULT '0',
  `nTicket` int(11) DEFAULT '0',
  `szDate` varchar(255) NOT NULL,
  `nDuration` int(11) DEFAULT '0',
  `szTagTitle` varchar(255) NOT NULL DEFAULT '',
  `szTagArtist` varchar(255) NOT NULL DEFAULT '',
  `szRequester` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`nID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gmod_radio_queue
-- ----------------------------
DROP TABLE IF EXISTS `gmod_radio_queue`;
CREATE TABLE `gmod_radio_queue` (
  `nID` int(11) NOT NULL AUTO_INCREMENT,
  `nTicket` int(11) NOT NULL,
  `nType` int(11) NOT NULL,
  `szDate` varchar(255) DEFAULT NULL,
  `szStatus` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`nID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gmod_vips
-- ----------------------------
DROP TABLE IF EXISTS `gmod_vips`;
CREATE TABLE `gmod_vips` (
  `nID` int(11) NOT NULL AUTO_INCREMENT,
  `szSteam` varchar(255) NOT NULL,
  `nType` int(11) NOT NULL,
  `szTag` varchar(255) NOT NULL DEFAULT '',
  `szName` varchar(255) NOT NULL DEFAULT '',
  `szChat` varchar(255) NOT NULL DEFAULT '',
  `nStart` bigint(20) DEFAULT NULL,
  `nLength` int(11) DEFAULT NULL,
  PRIMARY KEY (`nID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Records of gmod_vips
-- ----------------------------
-- Feel free to remove me from here. It's just so I can have some sort of reward
-- ----------------------------

INSERT INTO `gmod_vips` VALUES ('1', 'STEAM_0:0:OWNERSTEAM', '2', '', '', '', '1422541080', '0');
INSERT INTO `gmod_vips` VALUES ('2', 'STEAM_0:0:37549378', '2', '52 170 255 Creator', '257 0 0 Gravious', '255 255 255', '1418246264', '0');