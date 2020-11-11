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
