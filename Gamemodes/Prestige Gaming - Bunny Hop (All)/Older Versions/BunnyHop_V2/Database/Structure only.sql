/*
Navicat SQLite Data Transfer

Source Server         : peegee
Source Server Version : 30802
Source Host           : :0

Target Server Type    : SQLite
Target Server Version : 30802
File Encoding         : 65001

Date: 2015-01-30 00:22:03
*/

PRAGMA foreign_keys = OFF;

-- ----------------------------
-- Table structure for botdata
-- ----------------------------
DROP TABLE IF EXISTS "main"."botdata";
CREATE TABLE "botdata" (
	"map_name"  varchar(255),
	"player"  varchar(255) DEFAULT '',
	"time"  int,
	"type"  int DEFAULT 1
	);

-- ----------------------------
-- Table structure for mapareas
-- ----------------------------
DROP TABLE IF EXISTS "main"."mapareas";
CREATE TABLE "mapareas" (
"map_name"  varchar,
"type"  int,
"data"  text
);

-- ----------------------------
-- Table structure for mapdata
-- ----------------------------
DROP TABLE IF EXISTS "main"."mapdata";
CREATE TABLE "mapdata" (
"name"  varchar(255),
"spos1"  text,
"spos2"  text,
"epos1"  text,
"epos2"  text,
"points"  int,
"playcount"  int DEFAULT 0
);

-- ----------------------------
-- Table structure for playerauto
-- ----------------------------
DROP TABLE IF EXISTS "main"."playerauto";
CREATE TABLE "playerauto" (
	"map_name"  varchar(255),
	"name"  varchar(255) DEFAULT '',
	"unique_id"  varchar(255),
	"time"  int
	);

-- ----------------------------
-- Table structure for playerpdata
-- ----------------------------
DROP TABLE IF EXISTS "main"."playerpdata";
CREATE TABLE playerpdata ( infoid TEXT NOT NULL PRIMARY KEY, value TEXT );

-- ----------------------------
-- Table structure for playerrecords
-- ----------------------------
DROP TABLE IF EXISTS "main"."playerrecords";
CREATE TABLE playerrecords ( map_name varchar(255), name varchar(255) DEFAULT '', unique_id varchar(255), time1 int, time2 int, time3 int );
