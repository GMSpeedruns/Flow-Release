/*
Navicat SQLite Data Transfer

Source Server         : GarrysModDS
Source Server Version : 30714
Source Host           : :0

Target Server Type    : SQLite
Target Server Version : 30714
File Encoding         : 65001

Date: 2015-01-03 13:55:39
*/

PRAGMA foreign_keys = OFF;

-- ----------------------------
-- Table structure for game_bots
-- ----------------------------
CREATE TABLE IF NOT EXISTS "game_bots" (
"szMap"  TEXT NOT NULL,
"szPlayer"  TEXT,
"nTime"  INTEGER NOT NULL,
"nStyle"  INTEGER NOT NULL,
"szSteam"  TEXT NOT NULL,
"szDate"  TEXT
);

-- ----------------------------
-- Table structure for game_map
-- ----------------------------
CREATE TABLE IF NOT EXISTS "game_map" (
"szMap"  TEXT NOT NULL,
"nMultiplier"  INTEGER NOT NULL DEFAULT 1,
"nBonusMultiplier"  INTEGER,
"nPlays"  INTEGER NOT NULL DEFAULT 0,
"nOptions"  INTEGER,
PRIMARY KEY ("szMap" ASC)
);

-- ----------------------------
-- Table structure for game_times
-- ----------------------------
CREATE TABLE IF NOT EXISTS "game_times" (
"szUID"  TEXT NOT NULL,
"szPlayer"  TEXT,
"szMap"  TEXT NOT NULL,
"nStyle"  INTEGER NOT NULL,
"nTime"  INTEGER NOT NULL,
"nPoints"  INTEGER NOT NULL,
"vData"  TEXT,
"szDate"  TEXT
);

-- ----------------------------
-- Table structure for game_zones
-- ----------------------------
CREATE TABLE IF NOT EXISTS "game_zones" (
"szMap"  TEXT NOT NULL,
"nType"  INTEGER NOT NULL,
"vPos1"  TEXT,
"vPos2"  TEXT
);
