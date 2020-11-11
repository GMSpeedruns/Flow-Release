/*
Navicat SQLite Data Transfer

Source Server         : GarrysModDS
Source Server Version : 30802
Source Host           : :0

Target Server Type    : SQLite
Target Server Version : 30802
File Encoding         : 65001

Date: 2015-01-22 18:43:01
*/

PRAGMA foreign_keys = OFF;

-- ----------------------------
-- Table structure for dr_players
-- ----------------------------
DROP TABLE IF EXISTS "main"."dr_players";
CREATE TABLE "dr_players" (
"szID"  TEXT NOT NULL,
"nRank"  INTEGER NOT NULL DEFAULT 0,
"nJoins"  INTEGER NOT NULL DEFAULT 1,
"nMinutes"  INTEGER NOT NULL DEFAULT 0,
PRIMARY KEY ("szID")
);
