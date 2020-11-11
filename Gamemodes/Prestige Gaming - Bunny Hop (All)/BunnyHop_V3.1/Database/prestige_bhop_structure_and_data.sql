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
INSERT INTO `bhop_mapareas` VALUES ('1', 'bhop_exodus', '4', '-328,11992,4703;-2,-2,-1.5;2,2,1');
INSERT INTO `bhop_mapareas` VALUES ('2', 'bhop_exodus', '4', '-296,12095,4703;-2,-2,-1.5;2,2,1');
INSERT INTO `bhop_mapareas` VALUES ('3', 'bhop_exodus', '4', '-655,12151,4703;-2,-2,-1.5;2,2,1');
INSERT INTO `bhop_mapareas` VALUES ('4', 'bhop_exodus', '4', '-815,11920,4703;-2,-2,-1.5;2,2,1');
INSERT INTO `bhop_mapareas` VALUES ('5', 'bhop_exodus', '4', '-911,11840,4703;-2,-2,-1.5;2,2,1');
INSERT INTO `bhop_mapareas` VALUES ('6', 'bhop_exodus', '4', '-815,11808,4703;-2,-2,-1.5;2,2,1');
INSERT INTO `bhop_mapareas` VALUES ('7', 'bhop_exodus', '4', '-1071,11840,4703;-2,-2,-1.5;2,2,1');
INSERT INTO `bhop_mapareas` VALUES ('8', 'bhop_exodus', '1', '872,157,-295;1373,670,116');
INSERT INTO `bhop_mapareas` VALUES ('9', 'bhop_exodus', '2', '2416,8553,5701;2969,9120,5819;-11027,6770,2496');
INSERT INTO `bhop_mapareas` VALUES ('10', 'bhop_exodus', '2', '1995,8145,5031;3251,9390,5346;3207,8061,5072');
INSERT INTO `bhop_mapareas` VALUES ('11', 'bhop_exodus', '2', '-6369,-4993,4047;-6367,-4991,4049;-6368,-4992,4040');
INSERT INTO `bhop_mapareas` VALUES ('12', 'bhop_guly', '3', '2144.5,-1012,-84;level8');
INSERT INTO `bhop_mapareas` VALUES ('13', 'bhop_guly', '1', '-2541,-792,-157;-2001,-329,179');
INSERT INTO `bhop_mapareas` VALUES ('14', 'kz_bhop_indiana', '8', '-40,549,-2763;222,1154,-2364;16;18');
INSERT INTO `bhop_mapareas` VALUES ('15', 'kz_bhop_indiana', '8', '4131,4037,-4300;4492,4221,-4060;1;18');
INSERT INTO `bhop_mapareas` VALUES ('16', 'kz_bhop_indiana', '2', '4288,3370,-3872;4336,3460,-3680;4314,3814,-3870');
INSERT INTO `bhop_mapareas` VALUES ('17', 'bhop_cw_journey', '2', '15175,6853,640;15311,7023,725;12924,3997,624');
INSERT INTO `bhop_mapareas` VALUES ('18', 'bhop_infog', '4', '-2127.5,5608.5,39.5;-25.5,-6.5,-16.5;25.5,6.5,16.5');
INSERT INTO `bhop_mapareas` VALUES ('19', 'bhop_infog', '4', '2788,-2926,-757.5;-37,-119,-0.5;37,119,0.5');
INSERT INTO `bhop_mapareas` VALUES ('20', 'bhop_ananas', '2', '5948,-3972,576;6098,-3900,787;8429,-5231,1179');
INSERT INTO `bhop_mapareas` VALUES ('21', 'bhop_lost_world', '100', 'custom');
INSERT INTO `bhop_mapareas` VALUES ('22', 'bhop_arcane_v1', '1', '-1004,-965,14400;-716,920,14725');
INSERT INTO `bhop_mapareas` VALUES ('23', 'bhop_exquisite', '101', 'custom');
INSERT INTO `bhop_mapareas` VALUES ('24', 'bhop_areaportal_v1', '3', '-1032,-2696.5,-455;level_redcorridor7');
INSERT INTO `bhop_mapareas` VALUES ('25', 'bhop_areaportal_v1', '3', '-6947,-3655.5,-455;level_greencorridor3');
INSERT INTO `bhop_mapareas` VALUES ('26', 'bhop_catalyst', '9', '-8438,-58,5353');
INSERT INTO `bhop_mapareas` VALUES ('27', 'bhop_cartoons', '4', '2947,12856,167;3032,13862,297');
INSERT INTO `bhop_mapareas` VALUES ('28', 'bhop_cartoons', '4', '7315,4713,-2545;7375,5116,-2439');
INSERT INTO `bhop_mapareas` VALUES ('29', 'bhop_cartoons', '4', '6666,4705,-2552;6730,5179,-2452');
INSERT INTO `bhop_mapareas` VALUES ('30', 'bhop_badges_ausbhop', '4', '8000,-171,152;8314,492,214');
INSERT INTO `bhop_mapareas` VALUES ('31', 'bhop_badges_ausbhop', '4', '1958,-3649,152;2514,-2004,252');
INSERT INTO `bhop_mapareas` VALUES ('32', 'bhop_badges_ausbhop', '4', '-4794,-6579,152;-4151,-5531,267');
INSERT INTO `bhop_mapareas` VALUES ('33', 'bhop_miku_v2', '4', '-2900,874,-444;-2791,1006,-109');
INSERT INTO `bhop_mapareas` VALUES ('34', 'bhop_miku_v2', '4', '-2895,28,-444;-2799,123,-116');
INSERT INTO `bhop_mapareas` VALUES ('35', 'bhop_choice', '4', '11,-840,128;471,-685,668');
INSERT INTO `bhop_mapareas` VALUES ('36', 'bhop_sqee', '4', '2280,3776,-7751;0,0,0;446,446,5');
INSERT INTO `bhop_mapareas` VALUES ('37', 'bhop_eman_on', '2', '-4772,-12546,-3265;-4611,-12392,-3039;-5309,-11812,-1696');
INSERT INTO `bhop_mapareas` VALUES ('39', 'bhop_strafe_fix', '2', '-50,-2358,655;14,-2296,847;-626,-2393,2014');
INSERT INTO `bhop_mapareas` VALUES ('41', 'bhop_strafe_fix', '7', '16');
INSERT INTO `bhop_mapareas` VALUES ('42', 'kz_bhop_yonkoma', '7', '16');
INSERT INTO `bhop_mapareas` VALUES ('43', 'bhop_angkor', '9', '-1835,-94,2048');
INSERT INTO `bhop_mapareas` VALUES ('44', 'bhop_it_nine-up', '9', '-411,5490,-2126');
INSERT INTO `bhop_mapareas` VALUES ('45', 'bhop_depot', '9', '-15747,-11613,16');
INSERT INTO `bhop_mapareas` VALUES ('46', 'bhop_guly', '2', '504,-1136,-144;387,-1456,-100;-1614,-1290,-144');
INSERT INTO `bhop_mapareas` VALUES ('47', 'bhop_strafe_fix', '102', 'custom');
INSERT INTO `bhop_mapareas` VALUES ('48', 'bhop_thc_egypt', '9', '4555,6930,-1024');
INSERT INTO `bhop_mapareas` VALUES ('49', 'bhop_fly_lovers', '2', '-5552,10080,7616;-5232,10160,7646;-6088,9412,8896');
INSERT INTO `bhop_mapareas` VALUES ('50', 'bhop_lost_world', '2', '5448,4376,-352;6280,5240,500;7667,5063,128');
INSERT INTO `bhop_mapareas` VALUES ('51', 'bhop_lost_world', '9', '-234,-2945,-64');

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
INSERT INTO `records_maps` VALUES ('bhop_1n5an3_hard', '-496,-502,64', '-16,-17,251', '1743,-505,64', '2223,-305,244', '10', '0');
INSERT INTO `records_maps` VALUES ('bhop_1n5an3_harder', '-496,-413,64', '-17,-17,259', '1743,-505,64', '2223,-305,244', '20', '0');
INSERT INTO `records_maps` VALUES ('bhop_2flocci2furious', '-15009,-1952,4300', '-14793,-1162,4535', '-10957,12055,-10312', '-4846,13033,-9432', '200', '3');
INSERT INTO `records_maps` VALUES ('bhop_3d', '-496,16,0', '-80,430,256', '6672,-4719,-319', '7087,-4306,-127', '35', '2');
INSERT INTO `records_maps` VALUES ('bhop_addict_v2', '-4864,-2333,-2609', '-4482,-1952,-2466', '-4927,-2395,-47', '-4416,-1885,118', '80', '1');
INSERT INTO `records_maps` VALUES ('bhop_adventure_final', '1232,-2800,0', '1711,-2329,142', '2648,10448,-224', '2799,11183,143', '20', '0');
INSERT INTO `records_maps` VALUES ('bhop_advi_new', '1269,2525,-4945', '2194,2869,-4706', '602,-230,-763', '1068,233,-705', '15', '0');
INSERT INTO `records_maps` VALUES ('bhop_algebradude', '3218,-272,-48', '3407,463,109', '-240,400,-48', '239,879,162', '20', '0');
INSERT INTO `records_maps` VALUES ('bhop_ananas', '6018,-2292,427', '6047,-2088,644', '10438,-1876,2765', '11591,-467,2938', '100', '2');
INSERT INTO `records_maps` VALUES ('bhop_angkor', '-1888,-224,2048', '-1757,-0,2176', '868,-1345,-673', '1386,-560,-520', '50', '1');
INSERT INTO `records_maps` VALUES ('bhop_aoki_final', '1270,4594,-193', '1422,4793,27', '-7536,8500,332', '-7167,8815,422', '80', '0');
INSERT INTO `records_maps` VALUES ('bhop_aquatic_v1', '32,-161,16', '251,-33,151', '-916,705,16', '-707,980,182', '20', '0');
INSERT INTO `records_maps` VALUES ('bhop_arcane_v1', '1164,-496,14400', '1528,495,14527', '7908,-12561,13312', '8411,-12053,13666', '60', '0');
INSERT INTO `records_maps` VALUES ('bhop_areaportal_v1', '10688,-9541,-425', '11235,-9369,-283', '-9131,-119,-473', '-8008,997,-346', '50', '3');
INSERT INTO `records_maps` VALUES ('bhop_aztec_fixed', '0,-195,72', '399,-43,222', '-1935,-700,-164', '-1584,-487,-14', '10', '1');
INSERT INTO `records_maps` VALUES ('bhop_badges', '-6929,6833,736', '-6511,7055,942', '9744,10768,-6656', '11690,12781,-6313', '400', '0');
INSERT INTO `records_maps` VALUES ('bhop_badges_ausbhop', '-4840,-931,-32', '-4314,-663,140', '-1520,-6640,-72', '-1105,-5649,33', '80', '0');
INSERT INTO `records_maps` VALUES ('bhop_bitches_fix', '-304,16,128', '174,239,240', '1180,-677,76', '1507,337,211', '100', '2');
INSERT INTO `records_maps` VALUES ('bhop_bkz_goldbhop', '-248,59,16', '-41,277,151', '3072,1936,288', '3503,2527,418', '20', '0');
INSERT INTO `records_maps` VALUES ('bhop_blackrockshooter', '-3308,-131,63', '-2670,337,255', '6193,-11583,-255', '6967,-10835,-63', '35', '0');
INSERT INTO `records_maps` VALUES ('bhop_blue', '16,16,48', '367,249,83', '16,16,208', '367,367,278', '35', '0');
INSERT INTO `records_maps` VALUES ('bhop_boxes_snowy', '-1006,204,-319', '-529,495,-219', '73,-6864,-225', '680,-6283,-74', '10', '0');
INSERT INTO `records_maps` VALUES ('bhop_cartoons', '3044,11834,54', '3347,12002,100', '2946,11834,167', '3022,12326,287', '20', '1');
INSERT INTO `records_maps` VALUES ('bhop_catalyst', '-8604,-491,5353', '-8337,218,5480', '6722,213,-7586', '7415,909,-7219', '350', '0');
INSERT INTO `records_maps` VALUES ('bhop_ch4', '339,-468,64', '391,-138,192', '4040,874,15', '4559,1424,143', '50', '3');
INSERT INTO `records_maps` VALUES ('bhop_choice', '16,19,96', '495,171,276', '16,-1774,448', '495,-1496,643', '15', '0');
INSERT INTO `records_maps` VALUES ('bhop_clarity', '752,896,64', '1008,1008,256', '-3537,-4480,-1471', '-3472,-4320,-1279', '250', '0');
INSERT INTO `records_maps` VALUES ('bhop_cobblestone', '-175,208,128', '10,655,300', '162,2684,128', '284,2897,263', '10', '3');
INSERT INTO `records_maps` VALUES ('bhop_combine', '416,912,32', '650,1280,224', '-28,6480,-448', '780,7152,-256', '20', '0');
INSERT INTO `records_maps` VALUES ('bhop_cutekittenz', '-11056,9367,64', '-10340,10031,296', '-11036,9392,566', '-10360,9815,761', '200', '1');
INSERT INTO `records_maps` VALUES ('bhop_cw_journey', '2417,2136,1102', '2598,2318,1352', '-14919,-8191,-2228', '-13999,-7264,-1698', '80', '0');
INSERT INTO `records_maps` VALUES ('bhop_danmark', '96,144,96', '543,590,201', '7824,3856,96', '9039,4591,223', '50', '2');
INSERT INTO `records_maps` VALUES ('bhop_deluxe', '6,-110,64', '105,175,169', '-3498,1091,-86', '-3171,1232,19', '10', '1');
INSERT INTO `records_maps` VALUES ('bhop_depot', '-15520,-11760,16', '-15474,-11478,144', '-7815,1408,16', '-7542,1523,181', '200', '1');
INSERT INTO `records_maps` VALUES ('bhop_deppy', '7998,-9376,453', '8606,-9150,645', '-7522,4825,742', '-6915,5048,934', '100', '1');
INSERT INTO `records_maps` VALUES ('bhop_drop', '-11568,13265,-256', '-11089,13458,-161', '4267,1340,-7570', '4758,1815,-6335', '100', '1');
INSERT INTO `records_maps` VALUES ('bhop_dusted_v2', '397,528,128', '493,847,198', '-3167,-4319,64', '-2592,-3744,134', '70', '0');
INSERT INTO `records_maps` VALUES ('bhop_easyhop', '-544,-232,24', '-289,-16,129', '-832,-232,24', '-593,8,166', '5', '3');
INSERT INTO `records_maps` VALUES ('bhop_eazy', '-464,-464,64', '-241,-241,199', '-1104,-464,64', '-753,-113,164', '5', '5');
INSERT INTO `records_maps` VALUES ('bhop_eazy_v2', '-24,-176,48', '239,175,183', '4528,1744,48', '5042,2239,168', '10', '8');
INSERT INTO `records_maps` VALUES ('bhop_egyptiantemple', '-96,32,48', '416,280,176', '-4032,-896,968', '-3719,-583,1096', '80', '1');
INSERT INTO `records_maps` VALUES ('bhop_eject', '13802,2136,-160', '14213,3054,-40', '8216,-3048,-2888', '10215,-1049,-2716', '50', '0');
INSERT INTO `records_maps` VALUES ('bhop_eman_on', '-3630,-13430,545', '-3539,-13387,605', '-2586,-13168,-1920', '-2447,-13137,-1830', '1000', '0');
INSERT INTO `records_maps` VALUES ('bhop_empty_eyes', '-15216,14736,176', '-14992,15216,368', '-5822,-2543,8416', '-5057,-1725,8608', '120', '1');
INSERT INTO `records_maps` VALUES ('bhop_enmity_beta3', '-608,-208,72', '-250,-51,147', '-15496,3384,-1088', '-15401,3479,-968', '130', '0');
INSERT INTO `records_maps` VALUES ('bhop_exceptional', '1039,1040,-512', '1263,1775,-212', '-8048,912,-527', '-6161,2799,-10', '400', '0');
INSERT INTO `records_maps` VALUES ('bhop_exodus', '3312,815,1856', '3472,975,2130', '-976,1040,-768', '-550,1519,-611', '350', '0');
INSERT INTO `records_maps` VALUES ('bhop_exquisite', '-262,14,80', '274,444,230', '3172,-2411,-1536', '3295,-2195,-1364', '175', '0');
INSERT INTO `records_maps` VALUES ('bhop_extan', '5,-288,-72', '276,311,233', '-585,4224,-570', '144,4952,-445', '50', '1');
INSERT INTO `records_maps` VALUES ('bhop_factory_v2', '-1549,-624,-96', '-1071,687,24', '2504,-6178,-95', '2620,-5987,10', '100', '0');
INSERT INTO `records_maps` VALUES ('bhop_flocci', '-3743,-884,-1120', '-3285,-648,-1008', '-12041,-7117,476', '-10825,-5900,813', '220', '2');
INSERT INTO `records_maps` VALUES ('bhop_fly_fracture', '2601,-992,-600', '2856,-560,-472', '487,2802,384', '820,3107,512', '70', '2');
INSERT INTO `records_maps` VALUES ('bhop_fly_lovers', '-6192,9168,8896', '-6000,9648,9024', '5632,-1120,-3424', '5952,-801,-3296', '90', '4');
INSERT INTO `records_maps` VALUES ('bhop_forresttemple_beta', '340,16,187', '444,170,379', '2271,1636,287', '2518,1851,479', '150', '0');
INSERT INTO `records_maps` VALUES ('bhop_freakin', '4048,4496,144', '4336,4911,264', '6224,1168,-1280', '7343,1903,-1063', '200', '1');
INSERT INTO `records_maps` VALUES ('bhop_frost_bite_v1a', '1039,163,128', '1218,605,258', '-1234,1309,477', '-832,1721,627', '20', '0');
INSERT INTO `records_maps` VALUES ('bhop_fuckfear_fix', '-446,-62,64', '-196,190,256', '1736,-7,624', '1984,239,816', '110', '1');
INSERT INTO `records_maps` VALUES ('bhop_fury', '-8176,4499,64', '-7953,4634,236', '-7912,-1256,584', '-7449,-793,674', '200', '0');
INSERT INTO `records_maps` VALUES ('bhop_fury_2', '-11556,12448,-1888', '-11360,12544,-1760', '-8176,12600,1524', '-7824,13008,1652', '375', '2');
INSERT INTO `records_maps` VALUES ('bhop_giga_citadel_v2', '-2888,1208,-240', '-2823,1655,-90', '-6121,4253,-208', '-5759,4525,-58', '80', '0');
INSERT INTO `records_maps` VALUES ('bhop_glassy', '-15280,-15920,15952', '-15122,-15375,16080', '-11806,-15208,13120', '-10685,-13264,13248', '50', '1');
INSERT INTO `records_maps` VALUES ('bhop_greenhouse', '395,-3744,64', '548,-3385,224', '15456,-3744,64', '15661,-3385,249', '10', '1');
INSERT INTO `records_maps` VALUES ('bhop_greenroom_final', '1786,-1174,-1094', '2452,-206,-902', '3306,-1520,-2422', '4234,-432,-2230', '250', '0');
INSERT INTO `records_maps` VALUES ('bhop_guly', '-4233,-2332,-104', '-4140,-1889,31', '-2841,2236,-5', '-2316,2819,110', '100', '0');
INSERT INTO `records_maps` VALUES ('bhop_haddock', '560,-1392,1008', '683,-1073,1173', '-1594,-2008,-472', '-955,-1337,-262', '150', '0');
INSERT INTO `records_maps` VALUES ('bhop_hell', '-7598,601,-352', '-6403,738,-212', '4682,-2568,752', '6265,-1178,892', '120', '0');
INSERT INTO `records_maps` VALUES ('bhop_highfly', '-240,-672,9412', '151,-145,9602', '-2348,148,5700', '-1621,875,6097', '40', '2');
INSERT INTO `records_maps` VALUES ('bhop_hive', '-14400,13844,5', '-14239,14183,204', '-608,-1232,-9968', '95,-433,-9758', '300', '1');
INSERT INTO `records_maps` VALUES ('bhop_h_box_v1', '-368,273,-128', '368,432,0', '-640,-1664,-2112', '-383,-1407,-1984', '250', '0');
INSERT INTO `records_maps` VALUES ('bhop_idiosyncrasy', '-7261,2634,775', '-7123,2810,967', '-10033,-1735,404', '-9865,-1603,596', '200', '0');
INSERT INTO `records_maps` VALUES ('bhop_impecible', '512,-16,-736', '991,463,-609', '-5487,7644,255', '-5151,8319,412', '100', '0');
INSERT INTO `records_maps` VALUES ('bhop_impulse', '3152,592,0', '3375,736,75', '1424,-880,-256', '1518,-657,-144', '40', '0');
INSERT INTO `records_maps` VALUES ('bhop_infog', '1009,24,307', '1575,475,442', '-1214,-1566,-1066', '-1094,-1442,-1006', '300', '0');
INSERT INTO `records_maps` VALUES ('bhop_it_gbr', '-944,-12816,128', '-913,-12786,203', '-5594,4556,768', '-5545,4848,863', '130', '0');
INSERT INTO `records_maps` VALUES ('bhop_it_nine-up', '-3064,3711,-2016', '-3008,4173,-1824', '352,-5072,-1770', '523,-5015,-1578', '50', '2');
INSERT INTO `records_maps` VALUES ('bhop_ivy_final', '-3438,6462,114', '-3149,6570,248', '-6780,-1822,-2440', '-5084,-126,-2253', '250', '0');
INSERT INTO `records_maps` VALUES ('bhop_jierdas', '-66,191,592', '244,303,742', '2507,364,-1800', '2671,530,-1630', '15', '0');
INSERT INTO `records_maps` VALUES ('bhop_k26000_b2', '-491,38,64', '-166,361,192', '12427,100,70', '12735,421,256', '10', '0');
INSERT INTO `records_maps` VALUES ('bhop_kz_ocean', '-1484,668,32', '-1348,1120,212', '2395,-462,158', '2474,-281,333', '20', '0');
INSERT INTO `records_maps` VALUES ('bhop_kz_ravine', '-340,-1565,-139', '234,-994,407', '5519,-4913,-1462', '6212,-4223,-1027', '25', '0');
INSERT INTO `records_maps` VALUES ('bhop_kz_tryhardkittenz_fix', '-2936,-2769,253', '-2737,-2481,453', '-10593,-290,-2018', '-9438,1179,-1333', '200', '0');
INSERT INTO `records_maps` VALUES ('bhop_larena_nodoors', '24,-296,0', '808,296,128', '-496,14695,2112', '944,15208,2241', '45', '1');
INSERT INTO `records_maps` VALUES ('bhop_legenda_v2', '-566,-335,-99', '-400,-52,-17', '-4164,-4156,-842', '-4022,-4043,-745', '10', '0');
INSERT INTO `records_maps` VALUES ('bhop_legion', '-952,1352,0', '-618,1959,135', '4880,-3552,-440', '5295,-3328,-313', '25', '0');
INSERT INTO `records_maps` VALUES ('bhop_lego', '-240,162,128', '78,316,273', '1471,-8964,992', '1999,-8432,1597', '60', '0');
INSERT INTO `records_maps` VALUES ('bhop_letour', '109,78,96', '367,431,285', '48,16,528', '727,495,657', '120', '0');
INSERT INTO `records_maps` VALUES ('bhop_lolamap_v2', '-1060,846,128', '-602,1136,256', '2670,1265,-803', '4165,2621,-675', '20', '1');
INSERT INTO `records_maps` VALUES ('bhop_lost_world', '-208,-1112,80', '159,-649,230', '11936,-272,8160', '13167,879,8295', '150', '2');
INSERT INTO `records_maps` VALUES ('bhop_mcginis_fix', '-14576,-243,768', '-14352,110,896', '-8912,219,288', '-8360,912,416', '70', '1');
INSERT INTO `records_maps` VALUES ('bhop_messs_123', '1474,-445,-64', '1726,-193,198', '2,-174,320', '18,203,447', '25', '1');
INSERT INTO `records_maps` VALUES ('bhop_metal_v2', '-1390,16,64', '-912,496,256', '4431,-740,15', '5038,-143,207', '10', '0');
INSERT INTO `records_maps` VALUES ('bhop_miku_v2', '-2816,80,-444', '-2389,944,-129', '-2560,1342,-444', '-2307,1790,-264', '10', '0');
INSERT INTO `records_maps` VALUES ('bhop_militia_v2', '0,-662,72', '400,-24,264', '1267,-4940,72', '1667,-4540,264', '15', '0');
INSERT INTO `records_maps` VALUES ('bhop_mine', '-11609,12603,334', '-11427,13114,516', '9127,-393,-2975', '9759,339,-2654', '110', '1');
INSERT INTO `records_maps` VALUES ('bhop_mist', '-926,-1180,1297', '-641,-944,1454', '-1174,-1429,1307', '-1007,-1099,1380', '15', '0');
INSERT INTO `records_maps` VALUES ('bhop_mist_3', '-1766,-2146,-512', '-1425,-1873,-317', '-1663,-10832,-6203', '-1240,-10004,-5923', '15', '0');
INSERT INTO `records_maps` VALUES ('bhop_monster_beta', '-3720,-3720,64', '-3528,-3688,256', '2297,6069,304', '2613,6767,496', '50', '0');
INSERT INTO `records_maps` VALUES ('bhop_monster_jam', '400,-2668,3776', '879,-2193,3929', '5648,1680,3778', '6175,2287,4018', '40', '2');
INSERT INTO `records_maps` VALUES ('bhop_montana_fix', '-9764,3720,-1449', '-9489,4127,-1239', '-6880,-5300,3842', '-6022,-4561,4157', '100', '0');
INSERT INTO `records_maps` VALUES ('bhop_mp_stairs_dev', '-8,-180,64', '504,104,256', '-8,-8584,-704', '504,-8115,-512', '5', '1');
INSERT INTO `records_maps` VALUES ('bhop_nacho_libre_simo', '-1316,32,65', '-1100,480,258', '-2540,-3885,-1399', '-2260,-3605,-1206', '15', '0');
INSERT INTO `records_maps` VALUES ('bhop_nipple_fix', '89,-4833,48', '184,-4657,176', '5900,1296,-9520', '6124,1519,-9392', '70', '1');
INSERT INTO `records_maps` VALUES ('bhop_noobhop_exg', '-688,-1456,64', '-208,-975,192', '5454,2160,64', '6160,2576,192', '20', '1');
INSERT INTO `records_maps` VALUES ('bhop_null_fix', '-240,352,80', '250,510,245', '-2880,-2320,320', '-2499,-2070,672', '250', '0');
INSERT INTO `records_maps` VALUES ('bhop_omn', '756,13556,68', '1184,13745,195', '-2781,12072,-820', '-2439,12245,-625', '120', '1');
INSERT INTO `records_maps` VALUES ('bhop_paisaweeaboo_beta3', '-2032,-496,128', '-1819,547,298', '-1440,4880,-992', '-1217,5535,-722', '70', '0');
INSERT INTO `records_maps` VALUES ('bhop_pinky', '-240,350,16', '-17,456,83', '1040,1506,16', '1295,1686,98', '10', '0');
INSERT INTO `records_maps` VALUES ('bhop_portal', '-1153,831,532', '-769,1214,639', '-7536,4112,2816', '-6929,4719,2943', '170', '0');
INSERT INTO `records_maps` VALUES ('bhop_pro_bhopper_mp', '1985,0,-138', '2319,303,17', '-2400,989,-288', '-2097,1487,-143', '10', '0');
INSERT INTO `records_maps` VALUES ('bhop_quist_final', '-6350,9013,-115', '-6269,9955,40', '-3332,-8533,-105', '-3257,-7985,102', '120', '0');
INSERT INTO `records_maps` VALUES ('bhop_raw', '1554,-10732,66', '2485,-10664,258', '-6254,-10602,-845', '-6035,-10383,-653', '300', '0');
INSERT INTO `records_maps` VALUES ('bhop_red', '-640,-416,-32', '-270,416,160', '11024,-352,-32', '11728,352,160', '5', '0');
INSERT INTO `records_maps` VALUES ('bhop_redwood', '1710,-1712,72', '1968,-1456,264', '1700,1376,40', '1968,2896,232', '5', '1');
INSERT INTO `records_maps` VALUES ('bhop_sahara', '-815,-259,66', '-632,-58,194', '-1172,-427,-521', '-724,121,-393', '45', '1');
INSERT INTO `records_maps` VALUES ('bhop_serzv2_opti', '-1924,-12698,-14106', '-1219,-11994,-13981', '-1927,-12705,-11668', '-1218,-11987,-11453', '100', '0');
INSERT INTO `records_maps` VALUES ('bhop_sharpie', '-16240,-177,64', '-16145,175,294', '-9184,-1024,932', '-8185,-25,1177', '30', '0');
INSERT INTO `records_maps` VALUES ('bhop_sqee', '-1764,-8912,2368', '-1141,-8610,2585', '231,-1229,-11552', '1364,-883,-11260', '500', '0');
INSERT INTO `records_maps` VALUES ('bhop_strafe_fix', '-4131,3224,382', '-3843,3510,574', '755,12396,-4721', '888,12571,-4529', '500', '4');
INSERT INTO `records_maps` VALUES ('bhop_subsidence', '-209,1967,1696', '13,2479,1811', '1424,11408,128', '2159,12131,293', '70', '0');
INSERT INTO `records_maps` VALUES ('bhop_swik_b1', '-3056,-2032,-1024', '-2832,-1937,-896', '-1008,16,-1024', '-16,1008,-896', '45', '1');
INSERT INTO `records_maps` VALUES ('bhop_tasku', '-176,-708,128', '240,-336,256', '6348,-2827,-799', '6752,-2584,-591', '30', '0');
INSERT INTO `records_maps` VALUES ('bhop_thc', '1969,-1311,8', '2311,-992,180', '-9467,8466,9', '-9220,8785,128', '100', '1');
INSERT INTO `records_maps` VALUES ('bhop_thc_egypt', '4870,6662,-992', '4915,7161,-800', '3518,1982,-992', '3651,2515,-800', '45', '1');
INSERT INTO `records_maps` VALUES ('bhop_thc_gold', '-5624,-1008,99', '-5579,-17,220', '-13296,9225,104', '-12305,9261,319', '200', '0');
INSERT INTO `records_maps` VALUES ('bhop_thc_island', '-2839,-8592,96', '-2451,-8328,306', '3134,-1801,1007', '4107,-1453,1119', '175', '0');
INSERT INTO `records_maps` VALUES ('bhop_thc_platinum', '-13185,122,128', '-12900,390,256', '-1234,11451,-11569', '-276,11777,-11359', '200', '0');
INSERT INTO `records_maps` VALUES ('bhop_toc', '529,-240,-192', '751,239,-42', '9713,4225,-2304', '9999,4349,-2150', '120', '0');
INSERT INTO `records_maps` VALUES ('bhop_together', '1056,-4569,14796', '1615,-4258,14923', '496,3369,-10680', '726,3551,-10515', '110', '0');
INSERT INTO `records_maps` VALUES ('bhop_tut_v2', '-12785,-13295,48', '-12432,-13140,240', '-12272,-13296,144', '-11536,-12944,336', '30', '1');
INSERT INTO `records_maps` VALUES ('bhop_twisted', '58,48,96', '549,239,216', '8314,272,96', '8805,933,238', '60', '0');
INSERT INTO `records_maps` VALUES ('bhop_underground_crypt', '-772,-336,64', '-531,15,124', '-13767,2471,-1616', '-13255,2927,-1466', '200', '0');
INSERT INTO `records_maps` VALUES ('bhop_vanilla', '48,-1488,64', '463,-1297,219', '2256,1488,32', '2607,1999,182', '150', '0');
INSERT INTO `records_maps` VALUES ('bhop_veritas', '112,2000,200', '329,2479,312', '2576,-624,-752', '3038,-401,-617', '80', '0');
INSERT INTO `records_maps` VALUES ('bhop_wayz', '-240,-176,-64', '235,509,93', '3504,-2122,-671', '4382,-1099,161', '60', '0');
INSERT INTO `records_maps` VALUES ('bhop_white', '450,-375,144', '630,242,336', '4015,-22,61', '4561,523,253', '50', '0');
INSERT INTO `records_maps` VALUES ('bhop_wouit_v2', '-703,-1072,-384', '-529,-593,-279', '-2735,830,-269', '-1860,1188,-56', '175', '0');
INSERT INTO `records_maps` VALUES ('kz_bhop_cartooncastle_b1', '224,-1610,16', '608,-1390,208', '-1708,-175,16', '-1474,207,208', '15', '2');
INSERT INTO `records_maps` VALUES ('kz_bhop_indiana', '-264,-767,108', '192,-552,236', '4123,6743,-3104', '4191,6817,-2939', '500', '0');
INSERT INTO `records_maps` VALUES ('kz_bhop_yonkoma', '1615,4048,320', '1653,4239,410', '-6704,8848,-8944', '-6097,9233,-8679', '2000', '4');

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