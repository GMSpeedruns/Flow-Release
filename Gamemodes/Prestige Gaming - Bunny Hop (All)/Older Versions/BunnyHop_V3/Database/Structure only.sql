/*
Navicat MySQL Data Transfer

Source Server         : PG Bhop
Source Server Version : 50531
Source Host           : nope:3306
Source Database       : prestige_bhop

Target Server Type    : MYSQL
Target Server Version : 50531
File Encoding         : 65001

Date: 2014-02-18 22:20:41
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `bhop_botdata`
-- ----------------------------
DROP TABLE IF EXISTS `bhop_botdata`;
CREATE TABLE `bhop_botdata` (
  `nID` int(11) NOT NULL AUTO_INCREMENT,
  `szMap` varchar(255) NOT NULL,
  `szPlayer` varchar(255) DEFAULT 'Bot',
  `nTime` double NOT NULL,
  `nStyle` tinyint(4) NOT NULL DEFAULT '1',
  `szDate` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`nID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Records of bhop_botdata
-- ----------------------------

-- ----------------------------
-- Table structure for `bhop_limitations`
-- ----------------------------
DROP TABLE IF EXISTS `bhop_limitations`;
CREATE TABLE `bhop_limitations` (
  `nID` int(11) NOT NULL AUTO_INCREMENT,
  `szName` varchar(255) DEFAULT NULL,
  `nUID` bigint(20) NOT NULL,
  `nExpire` int(11) NOT NULL DEFAULT '0',
  `szReason` varchar(255) DEFAULT 'Empty',
  `szDate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `szAdmin` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`nID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Records of bhop_limitations
-- ----------------------------

-- ----------------------------
-- Table structure for `bhop_mapareas`
-- ----------------------------
DROP TABLE IF EXISTS `bhop_mapareas`;
CREATE TABLE `bhop_mapareas` (
  `nID` int(11) NOT NULL AUTO_INCREMENT,
  `szMap` varchar(255) NOT NULL,
  `nType` tinyint(4) NOT NULL,
  `szData` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`nID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Records of bhop_mapareas
-- ----------------------------

-- ----------------------------
-- Table structure for `records_maps`
-- ----------------------------
DROP TABLE IF EXISTS `records_maps`;
CREATE TABLE `records_maps` (
  `szMap` varchar(255) NOT NULL,
  `vStart1` varchar(255) DEFAULT NULL,
  `vStart2` varchar(255) DEFAULT NULL,
  `vEnd1` varchar(255) DEFAULT NULL,
  `vEnd2` varchar(255) DEFAULT NULL,
  `nPoints` int(10) unsigned NOT NULL DEFAULT '0',
  `nPlays` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`szMap`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Records of records_maps
-- ----------------------------

-- ----------------------------
-- Table structure for `records_normal`
-- ----------------------------
DROP TABLE IF EXISTS `records_normal`;
CREATE TABLE `records_normal` (
  `szMap` varchar(255) NOT NULL,
  `szName` varchar(255) DEFAULT NULL,
  `nID` bigint(20) unsigned NOT NULL,
  `nTime` double unsigned NOT NULL,
  `nWeight` double unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Records of records_normal
-- ----------------------------

-- ----------------------------
-- Table structure for `records_rank`
-- ----------------------------
DROP TABLE IF EXISTS `records_rank`;
CREATE TABLE `records_rank` (
  `nID` bigint(20) unsigned NOT NULL,
  `nTotalWeight` double unsigned DEFAULT NULL,
  PRIMARY KEY (`nID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Records of records_rank
-- ----------------------------

-- ----------------------------
-- Table structure for `records_special`
-- ----------------------------
DROP TABLE IF EXISTS `records_special`;
CREATE TABLE `records_special` (
  `szMap` varchar(255) NOT NULL,
  `szName` varchar(255) DEFAULT NULL,
  `nID` bigint(20) unsigned NOT NULL,
  `nTime` double unsigned NOT NULL,
  `nStyle` tinyint(3) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;