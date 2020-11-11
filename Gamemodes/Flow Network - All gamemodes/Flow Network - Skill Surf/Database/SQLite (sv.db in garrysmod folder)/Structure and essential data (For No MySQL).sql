/*
Navicat SQLite Data Transfer

Source Server         : Kessss
Source Server Version : 30802
Source Host           : :0

Target Server Type    : SQLite
Target Server Version : 30802
File Encoding         : 65001

Date: 2015-01-29 15:57:35
*/

PRAGMA foreign_keys = OFF;

-- ----------------------------
-- Table structure for game_bots
-- ----------------------------
DROP TABLE IF EXISTS "game_bots";
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
DROP TABLE IF EXISTS "game_map";
CREATE TABLE IF NOT EXISTS "game_map" (
"szMap"  TEXT NOT NULL,
"nMultiplier"  INTEGER NOT NULL DEFAULT 1,
"nTier"  INTEGER NOT NULL DEFAULT 0,
"nType"  INTEGER,
"nBonusMultiplier"  INTEGER,
"nPlays"  INTEGER NOT NULL DEFAULT 0,
"nOptions"  INTEGER,
PRIMARY KEY ("szMap" ASC)
);

-- ----------------------------
-- Table structure for game_times
-- ----------------------------
DROP TABLE IF EXISTS "game_times";
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
DROP TABLE IF EXISTS "game_zones";
CREATE TABLE IF NOT EXISTS "game_zones" (
"szMap"  TEXT NOT NULL,
"nType"  INTEGER NOT NULL,
"vPos1"  TEXT,
"vPos2"  TEXT
);

---------------------
-- All essential data
---------------------

INSERT INTO "main"."game_map" VALUES ('surf_beginner', 10, 1, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_utopia_njv', 20, 1, 0, null, 0, 1);
INSERT INTO "main"."game_map" VALUES ('surf_derpis_ksf', 20, 1, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_kitsune', 25, 1, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_lt_omnific', 350, 6, 1, 30, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_sinsane_ksf', 600, 6, 0, 30, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_island', 25, 2, 0, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_2012_njv', 20, 2, 1, 2, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_4dimensional', 125, 4, 1, 10, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_6', 30, 2, 0, 15, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_adtr_njv', 15, 2, 1, 2, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_aether', 10, 2, 0, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_again_njv', 125, 5, 0, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_airflow', 110, 4, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_annoyance_njv', 70, 3, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_auroria_ksf', 60, 3, 1, 6, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_blackside', 110, 4, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_fast', 100, 4, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_sunnyhappylove', 30, 1, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_happyhands', 30, 2, 0, 2, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_classics', 60, 3, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_kz_protraining', 5, 1, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_blub_njv', 125, 4, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_bob', 20, 2, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_chaos_fix', 15, 1, 1, null, 0, 1);
INSERT INTO "main"."game_map" VALUES ('surf_classics2', 70, 3, 1, null, 0, 2);
INSERT INTO "main"."game_map" VALUES ('surf_core_refix', 275, 6, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_creation', 120, 3, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_cyanide', 70, 3, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_depressing', 140, 4, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_dusk', 70, 3, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_elysium', 135, 5, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_extremex2_5', 190, 5, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_faint_fix', 40, 2, 0, 10, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_flappybird', 250, 6, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_frequency_no_jail', 115, 4, 0, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_heaven_njv', 50, 3, 1, 5, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_infected', 80, 3, 0, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_inrage2', 100, 4, 0, 5, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_lessons', 15, 1, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_map_h', 150, 5, 0, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_mash-up', 90, 3, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_masonry', 125, 4, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_mesa_mine', 30, 2, 0, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_metallic', 150, 5, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_methadone', 70, 3, 1, 5, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_misc', 140, 5, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_mushroom_ksf', 100, 3, 0, 5, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_nemesis', 100, 4, 0, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_nightmare', 200, 5, 1, 200, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_nikolo', 130, 4, 0, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_ny_advance_nojail', 65, 3, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_pandemonium_njv', 80, 4, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_placid', 90, 3, 0, 3, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_paroxysm_njv', 50, 2, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_plethora_fix', 85, 4, 0, 1, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_prelude_ksf', 10, 1, 0, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_primero', 135, 5, 0, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_pyrism_njv', 500, 6, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_quilavar', 70, 3, 0, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_rookie', 50, 3, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_sandman_v2', 130, 4, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_savant_njv', 80, 4, 1, 7, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_sci_fi', 90, 3, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_sempar_njv', 100, 4, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_smile_njv', 40, 2, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_stonework', 150, 4, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_stonework2', 80, 3, 0, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_stonework3', 225, 5, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_sundown_njv', 15, 1, 0, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_tensile_njv', 60, 2, 0, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_thembrium_njv', 70, 3, 1, 10, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_tronic_njv', 200, 5, 0, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_unusual_njv', 165, 5, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_calamity_njv', 60, 3, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_calamity2', 70, 4, 1, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_and_destroy', 10, 1, 0, 2, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_dionysus', 200, 5, 0, null, 0, null);
INSERT INTO "main"."game_map" VALUES ('surf_forbidden_ways_ksf', 10, 1, 0, 1, 0, 1);
INSERT INTO "main"."game_map" VALUES ('surf_funhouse_njv', 10, 1, 0, null, 0, null);

INSERT INTO "main"."game_zones" VALUES ('surf_beginner', 0, '-433.19 -47.97 320.03', '173.92 239.69 448.03');
INSERT INTO "main"."game_zones" VALUES ('surf_beginner', 1, '-6063.97 4868.88 -263.97', '-4547.67 5238.07 -135.97');
INSERT INTO "main"."game_zones" VALUES ('surf_utopia_njv', 0, '-14146.83 -315.36 12800.03', '-13884.64 321.43 12928.03');
INSERT INTO "main"."game_zones" VALUES ('surf_utopia_njv', 1, '-14319.99 -704.78 -6223.97', '-13899.16 734.77 -6095.97');
INSERT INTO "main"."game_zones" VALUES ('surf_derpis_ksf', 0, '-11127.64 -12023.21 11296.03', '-10888.22 -11528.86 11424.03');
INSERT INTO "main"."game_zones" VALUES ('surf_derpis_ksf', 1, '2185.30 12551.95 6560.03', '2679.04 13047.79 6688.03');
INSERT INTO "main"."game_zones" VALUES ('surf_kitsune', 0, '-15743.81 -15343.97 816.03', '-14975.71 -14832.93 944.03');
INSERT INTO "main"."game_zones" VALUES ('surf_kitsune', 1, '-16047.97 9792.03 -11935.97', '-15536.87 10560.30 -11807.97');
INSERT INTO "main"."game_zones" VALUES ('surf_sinsane_ksf', 0, '14113.02 839.73 13772.03', '14242.32 1210.73 13900.03');
INSERT INTO "main"."game_zones" VALUES ('surf_sinsane_ksf', 1, '2311.56 819.56 383.86', '2742.71 1254.70 535.72');
INSERT INTO "main"."game_zones" VALUES ('surf_island', 0, '-512.14 452.78 14528.03', '513.16 511.86 14656.03');
INSERT INTO "main"."game_zones" VALUES ('surf_island', 1, '5136.03 5269.89 -11007.97', '13294.98 6127.97 -9305.46');
INSERT INTO "main"."game_zones" VALUES ('surf_2012_njv', 0, '4910.10 -3582.50 1280.03', '5348.70 -3398.84 1408.03');
INSERT INTO "main"."game_zones" VALUES ('surf_2012_njv', 1, '-1391.70 10867.05 7488.03', '-1155.43 10979.97 7616.03');
INSERT INTO "main"."game_zones" VALUES ('surf_4dimensional', 0, '-2354.39 -1563.89 7536.03', '-2070.32 -559.95 7664.03');
INSERT INTO "main"."game_zones" VALUES ('surf_4dimensional', 1, '-3756.51 -2431.97 7536.03', '-3056.03 335.97 7664.03');
INSERT INTO "main"."game_zones" VALUES ('surf_lt_omnific', 0, '6795.15 10674.89 -767.97', '7148.83 12047.95 -639.97');
INSERT INTO "main"."game_zones" VALUES ('surf_lt_omnific', 1, '2901.14 -175.97 14080.03', '3183.97 175.99 14208.03');
INSERT INTO "main"."game_zones" VALUES ('surf_6', 0, '3088.03 -315.82 6368.03', '3449.69 317.31 6496.03');
INSERT INTO "main"."game_zones" VALUES ('surf_6', 1, '-11311.97 -508.41 -6335.97', '-10886.30 570.57 -6207.97');
INSERT INTO "main"."game_zones" VALUES ('surf_adtr_njv', 0, '893.73 2435.58 1262.54', '1957.86 2924.29 1433.73');
INSERT INTO "main"."game_zones" VALUES ('surf_adtr_njv', 1, '-1014.86 465.00 -1674.88', '-827.88 641.41 -1521.18');
INSERT INTO "main"."game_zones" VALUES ('surf_aether', 1, '1547.13 13832.35 6208.03', '2553.48 14839.98 6336.03');
INSERT INTO "main"."game_zones" VALUES ('surf_aether', 0, '-9363.04 8208.03 13728.03', '-9068.21 8434.28 13856.03');
INSERT INTO "main"."game_zones" VALUES ('surf_again_njv', 0, '-236.93 420.19 5744.03', '107.89 764.46 5872.03');
INSERT INTO "main"."game_zones" VALUES ('surf_again_njv', 1, '-256.90 -2583.68 -13595.47', '113.02 -2225.19 -13418.67');
INSERT INTO "main"."game_zones" VALUES ('surf_airflow', 0, '-282.23 -1515.57 -442.30', '277.81 490.66 -286.64');
INSERT INTO "main"."game_zones" VALUES ('surf_airflow', 1, '-2607.97 3837.59 -11471.97', '-592.01 4111.97 -11343.97');
INSERT INTO "main"."game_zones" VALUES ('surf_amplitude_apex', 0, '-14026.88 11610.03 1902.03', '-13996.65 12473.99 2030.03');
INSERT INTO "main"."game_zones" VALUES ('surf_amplitude_apex', 1, '13360.78 -5174.77 -9532.97', '13714.60 -4760.21 -9404.97');
INSERT INTO "main"."game_zones" VALUES ('surf_annoyance_njv', 0, '-498.32 -13678.52 2553.87', '497.26 -13141.24 2696.56');
INSERT INTO "main"."game_zones" VALUES ('surf_annoyance_njv', 1, '11459.81 -6783.16 -1375.97', '11966.90 -6271.83 -1119.20');
INSERT INTO "main"."game_zones" VALUES ('surf_auroria_ksf', 0, '-1000.37 926.00 1964.03', '-735.13 1331.97 2092.03');
INSERT INTO "main"."game_zones" VALUES ('surf_auroria_ksf', 1, '-1420.04 4699.01 -117.97', '-942.65 5056.61 161.51');
INSERT INTO "main"."game_zones" VALUES ('surf_blackside', 0, '-12408.52 13112.99 12117.73', '-11394.66 14532.58 12245.73');
INSERT INTO "main"."game_zones" VALUES ('surf_blackside', 1, '5909.73 -12666.22 3168.03', '6282.95 -11607.56 3296.03');
INSERT INTO "main"."game_zones" VALUES ('surf_rands', 0, '11.54 -16256.68 16138.46', '57.81 -16170.53 16283.72');
INSERT INTO "main"."game_zones" VALUES ('surf_fast', 0, '85.21 2400.46 -12927.97', '503.45 2719.05 -12799.97');
INSERT INTO "main"."game_zones" VALUES ('surf_fast', 1, '6797.95 -10368.16 -5487.97', '7551.16 -9615.46 -4776.71');
INSERT INTO "main"."game_zones" VALUES ('surf_sunnyhappylove', 0, '13808.03 -1887.97 4384.03', '14794.20 767.97 4512.03');
INSERT INTO "main"."game_zones" VALUES ('surf_sunnyhappylove', 1, '-13520.08 8944.03 -11567.97', '-12299.46 14639.99 -11439.97');
INSERT INTO "main"."game_zones" VALUES ('surf_overgrowth2', 0, '870.90 2977.64 15232.03', '1359.97 4655.97 15360.03');
INSERT INTO "main"."game_zones" VALUES ('surf_overgrowth2', 1, '2574.86 11660.06 -13055.97', '2925.01 11996.83 -12927.97');
INSERT INTO "main"."game_zones" VALUES ('surf_happyhands', 0, '-10911.97 13792.03 9440.03', '-10520.27 14784.00 9568.03');
INSERT INTO "main"."game_zones" VALUES ('surf_happyhands', 1, '9472.03 12011.72 -2088.79', '10703.97 12287.97 -1959.97');
INSERT INTO "main"."game_zones" VALUES ('surf_kz_protraining', 0, '-12915.00 -226.17 576.03', '-12678.52 -13.45 704.03');
INSERT INTO "main"."game_zones" VALUES ('surf_kz_protraining', 1, '6056.46 9354.54 2080.03', '6422.66 9712.00 2208.03');
INSERT INTO "main"."game_zones" VALUES ('surf_blub_njv', 0, '-143.97 -12335.97 384.03', '591.97 -12045.35 512.03');
INSERT INTO "main"."game_zones" VALUES ('surf_blub_njv', 1, '3416.03 -6478.16 -6015.97', '4028.87 -6362.22 -5615.28');
INSERT INTO "main"."game_zones" VALUES ('surf_bob', 0, '3601.16 -8687.60 13184.03', '4079.97 -8208.03 13312.03');
INSERT INTO "main"."game_zones" VALUES ('surf_bob', 1, '656.02 -12143.97 15488.03', '1007.97 -11525.24 15628.59');
INSERT INTO "main"."game_zones" VALUES ('Surf_boring', 0, '2130.55 -100.15 4848.03', '2254.03 132.40 4976.03');
INSERT INTO "main"."game_zones" VALUES ('Surf_calamity_njv', 0, '3054.01 -1380.03 -4890.97', '3245.79 -1187.14 -4762.97');
INSERT INTO "main"."game_zones" VALUES ('Surf_calamity_njv', 1, '7529.57 -2726.53 -10735.97', '10168.92 -2575.36 -9024.96');
INSERT INTO "main"."game_zones" VALUES ('Surf_calamity2', 0, '-1482.62 7308.64 2605.03', '-1292.58 7495.21 2733.03');
INSERT INTO "main"."game_zones" VALUES ('Surf_calamity2', 1, '-4383.55 -13318.91 -8095.97', '-4238.01 -10656.03 -6528.80');
INSERT INTO "main"."game_zones" VALUES ('surf_chaos_fix', 0, '-12352.46 14417.44 12348.03', '-11361.19 15315.33 12476.03');
INSERT INTO "main"."game_zones" VALUES ('surf_chaos_fix', 1, '13286.63 11347.66 -14265.97', '14586.43 12537.75 -13970.96');
INSERT INTO "main"."game_zones" VALUES ('surf_classics', 0, '-7576.76 -15332.97 14890.43', '-6849.03 -14213.03 15018.43');
INSERT INTO "main"."game_zones" VALUES ('surf_classics', 1, '-2180.42 10063.62 -13079.97', '-1941.96 10144.00 -12951.97');
INSERT INTO "main"."game_zones" VALUES ('surf_classics2', 0, '13012.67 12528.30 14742.13', '13323.54 12882.71 14915.93');
INSERT INTO "main"."game_zones" VALUES ('surf_classics2', 1, '-8630.38 -2428.91 -14112.08', '-7662.51 -1840.51 -13553.03');
INSERT INTO "main"."game_zones" VALUES ('surf_core_refix', 0, '-2768.56 -97.95 1724.03', '-2558.16 137.47 1852.03');
INSERT INTO "main"."game_zones" VALUES ('surf_core_refix', 1, '-3387.19 12910.98 608.40', '-3104.68 13725.47 1165.15');
INSERT INTO "main"."game_zones" VALUES ('surf_creation', 0, '-8990.77 -48.00 1687.79', '-8741.69 368.05 1824.03');
INSERT INTO "main"."game_zones" VALUES ('surf_creation', 1, '2494.02 -235.62 4046.03', '3082.78 403.13 4174.03');
INSERT INTO "main"."game_zones" VALUES ('surf_cyanide', 0, '-294.99 -11750.14 13816.03', '296.62 -11288.70 13944.03');
INSERT INTO "main"."game_zones" VALUES ('surf_cyanide', 1, '6677.87 -7662.57 -6655.97', '7666.79 -6670.53 -6269.58');
INSERT INTO "main"."game_zones" VALUES ('surf_delusional', 0, '-12709.84 8856.99 1984.03', '-12358.48 9384.43 2112.03');
INSERT INTO "main"."game_zones" VALUES ('surf_depressing', 0, '-7147.55 6096.89 -98.97', '-6637.37 6297.09 29.03');
INSERT INTO "main"."game_zones" VALUES ('surf_depressing', 1, '2447.51 -9349.57 -5531.97', '2665.83 -9154.02 -5403.97');
INSERT INTO "main"."game_zones" VALUES ('surf_diamond_beta1', 0, '-3134.18 -512.18 15296.03', '-2631.79 -1.34 15424.03');
INSERT INTO "main"."game_zones" VALUES ('surf_dusk', 0, '288.10 -397.39 -1882.47', '745.77 -162.62 -1754.47');
INSERT INTO "main"."game_zones" VALUES ('surf_dusk', 1, '10174.72 -5734.57 -861.97', '10878.47 -5156.72 -566.78');
INSERT INTO "main"."game_zones" VALUES ('surf_eclipse', 0, '-11651.66 9832.33 11795.25', '-11531.32 10372.67 12024.95');
INSERT INTO "main"."game_zones" VALUES ('surf_elysium', 0, '-15068.97 -5765.22 -4415.97', '-14630.22 -5003.99 -4287.97');
INSERT INTO "main"."game_zones" VALUES ('surf_elysium', 1, '5134.83 10236.75 7776.03', '5391.97 11404.52 7904.03');
INSERT INTO "main"."game_zones" VALUES ('surf_extremex2_5', 0, '-10173.18 -2190.50 2688.03', '-9792.68 -1903.59 2816.03');
INSERT INTO "main"."game_zones" VALUES ('surf_extremex2_5', 1, '-3974.76 3082.62 -5055.97', '-3538.71 5109.45 -4491.95');
INSERT INTO "main"."game_zones" VALUES ('surf_faint_fix', 0, '-5211.97 402.95 -159.97', '-4942.01 655.06 -31.97');
INSERT INTO "main"."game_zones" VALUES ('surf_faint_fix', 1, '1178.01 -280.47 -9275.58', '1918.12 541.59 -9125.64');
INSERT INTO "main"."game_zones" VALUES ('surf_flappybird', 0, '-15855.97 -507.88 1162.03', '-15564.49 184.75 1290.03');
INSERT INTO "main"."game_zones" VALUES ('surf_flappybird', 1, '-565.97 2358.82 -9539.41', '-200.55 3001.12 -9411.41');
INSERT INTO "main"."game_zones" VALUES ('surf_flyin_fortress', 0, '-511.81 -2286.40 7040.03', '0.82 -1868.29 7168.03');
INSERT INTO "main"."game_zones" VALUES ('surf_freedom', 0, '-189.81 4609.47 11328.03', '-65.59 5375.13 11548.47');
INSERT INTO "main"."game_zones" VALUES ('surf_freedom', 1, '14209.35 9597.50 -1279.97', '14718.40 10885.04 -726.89');
INSERT INTO "main"."game_zones" VALUES ('surf_frequency_no_jail', 0, '-1359.77 5957.80 7840.03', '-1178.46 6269.78 7968.03');
INSERT INTO "main"."game_zones" VALUES ('surf_frequency_no_jail', 1, '1186.70 5809.02 -9615.97', '1434.28 6415.60 -9383.42');
INSERT INTO "main"."game_zones" VALUES ('surf_heaven_njv', 0, '2980.96 -1755.97 5158.03', '3114.89 -956.03 5286.03');
INSERT INTO "main"."game_zones" VALUES ('surf_heaven_njv', 1, '2886.96 -5628.83 431.05', '3326.45 -5226.60 622.25');
INSERT INTO "main"."game_zones" VALUES ('surf_helium_v2', 0, '-641.00 -1785.99 2959.03', '-236.03 -1561.91 3087.03');
INSERT INTO "main"."game_zones" VALUES ('surf_helium_v2', 1, '-7943.47 9875.03 -3445.48', '-7424.82 10390.28 -3158.41');
INSERT INTO "main"."game_zones" VALUES ('surf_illumination', 0, '2241.91 -415.97 11296.03', '2464.87 159.97 11424.03');
INSERT INTO "main"."game_zones" VALUES ('surf_impact', 0, '-3529.07 -2002.87 -314.72', '-3357.91 -1627.19 -186.72');
INSERT INTO "main"."game_zones" VALUES ('surf_infected', 0, '-12991.91 -194.98 9034.03', '-12671.22 191.00 9162.03');
INSERT INTO "main"."game_zones" VALUES ('surf_infected', 1, '5295.97 7953.26 -4863.97', '5588.66 8415.99 -4735.97');
INSERT INTO "main"."game_zones" VALUES ('surf_inrage2', 0, '4857.82 -2635.20 6633.46', '7095.16 -2186.88 6767.62');
INSERT INTO "main"."game_zones" VALUES ('surf_inrage2', 1, '-3986.18 10059.21 -645.66', '-3412.67 10302.02 -475.10');
INSERT INTO "main"."game_zones" VALUES ('surf_kawaii', 0, '873.03 3835.03 1991.03', '1121.76 4314.97 2119.03');
INSERT INTO "main"."game_zones" VALUES ('surf_kawaii', 1, '-1772.73 -5772.92 -364.97', '-1735.17 -5390.15 -219.97');
INSERT INTO "main"."game_zones" VALUES ('surf_lessons', 0, '-144.22 -250.83 -61.71', '132.10 236.69 99.37');
INSERT INTO "main"."game_zones" VALUES ('surf_lessons', 1, '1516.47 -8543.97 -4555.97', '2079.98 -8165.05 -4284.83');
INSERT INTO "main"."game_zones" VALUES ('surf_lodypreview', 0, '6367.07 9229.26 9494.03', '6731.97 9704.47 9844.24');
INSERT INTO "main"."game_zones" VALUES ('surf_map_h', 0, '-239.97 -5198.81 6400.03', '239.97 -4784.02 6528.03');
INSERT INTO "main"."game_zones" VALUES ('surf_map_h', 1, '6048.34 -4047.97 -6879.97', '6240.21 -3360.31 -6751.97');
INSERT INTO "main"."game_zones" VALUES ('surf_mash-up', 0, '-12303.97 13208.03 10747.03', '-12014.31 14583.97 10875.03');
INSERT INTO "main"."game_zones" VALUES ('surf_mash-up', 1, '-4425.56 -9115.56 -7819.97', '-4173.12 -8865.04 -7691.97');
INSERT INTO "main"."game_zones" VALUES ('surf_masonry', 0, '322.08 -88.18 6416.03', '507.78 77.13 6544.03');
INSERT INTO "main"."game_zones" VALUES ('surf_masonry', 1, '14541.97 -541.82 -13375.97', '15247.97 544.65 -12990.45');
INSERT INTO "main"."game_zones" VALUES ('surf_mesa_mine', 0, '-128.66 -14032.51 15024.03', '126.94 -13807.66 15152.03');
INSERT INTO "main"."game_zones" VALUES ('surf_mesa_mine', 1, '14059.16 -4726.10 -15375.97', '14611.57 -4062.20 -15054.25');
INSERT INTO "main"."game_zones" VALUES ('surf_metallic', 0, '3506.88 -99.69 16.03', '3660.26 98.84 144.03');
INSERT INTO "main"."game_zones" VALUES ('surf_metallic', 1, '-4479.97 -3055.99 -5303.97', '-3779.40 -2882.72 -4963.88');
INSERT INTO "main"."game_zones" VALUES ('surf_methadone', 0, '-6765.54 2285.46 -1000.60', '-6496.40 2661.28 -816.83');
INSERT INTO "main"."game_zones" VALUES ('surf_methadone', 1, '-1403.42 10401.43 1578.13', '-528.03 11159.83 1791.72');
INSERT INTO "main"."game_zones" VALUES ('surf_misc', 0, '-5480.93 -618.53 -1625.97', '-4109.03 1131.98 -1210.13');
INSERT INTO "main"."game_zones" VALUES ('surf_misc', 1, '8321.29 12029.10 5390.03', '9154.95 12573.12 5654.38');
INSERT INTO "main"."game_zones" VALUES ('surf_mushroom_ksf', 0, '562.99 -180.13 32.03', '913.42 156.70 160.03');
INSERT INTO "main"."game_zones" VALUES ('surf_nemesis', 0, '392.72 53.48 11848.03', '991.89 882.44 11976.03');
INSERT INTO "main"."game_zones" VALUES ('surf_nemesis', 1, '3116.73 9760.33 -12809.97', '4522.41 10780.66 -12326.65');
INSERT INTO "main"."game_zones" VALUES ('surf_nightmare', 0, '5525.70 7773.57 -1096.48', '5847.07 8096.06 -968.24');
INSERT INTO "main"."game_zones" VALUES ('surf_nightmare', 1, '6368.81 319.60 9328.03', '6493.10 719.14 9543.55');
INSERT INTO "main"."game_zones" VALUES ('surf_nikolo', 0, '-12524.29 -3423.97 11200.03', '-11366.40 -2932.66 11328.03');
INSERT INTO "main"."game_zones" VALUES ('surf_nikolo', 1, '-13505.45 -5241.45 -2965.35', '-10336.03 -4752.03 -1908.03');
INSERT INTO "main"."game_zones" VALUES ('surf_ny_advance_nojail', 0, '-127.01 -324.24 -159.97', '128.01 -129.23 -31.97');
INSERT INTO "main"."game_zones" VALUES ('surf_ny_advance_nojail', 1, '455.84 -47.36 9803.44', '1455.10 922.95 10072.66');
INSERT INTO "main"."game_zones" VALUES ('surf_pandemonium_njv', 0, '9245.85 -9242.75 -8877.97', '9633.21 -8855.99 -8749.97');
INSERT INTO "main"."game_zones" VALUES ('surf_pandemonium_njv', 1, '8607.55 -13547.89 59.05', '9154.12 -12627.06 218.00');
INSERT INTO "main"."game_zones" VALUES ('surf_placid', 0, '-1466.55 -712.90 11664.03', '-1219.08 -380.13 11792.03');
INSERT INTO "main"."game_zones" VALUES ('surf_placid', 1, '-2730.94 5088.01 -10679.97', '-912.03 5736.86 -10226.28');
INSERT INTO "main"."game_zones" VALUES ('surf_paroxysm_njv', 0, '-108.71 -298.18 80.03', '238.66 44.52 208.03');
INSERT INTO "main"."game_zones" VALUES ('surf_paroxysm_njv', 1, '-12329.45 -402.47 -435.97', '-12135.15 1820.00 322.40');
INSERT INTO "main"."game_zones" VALUES ('surf_plethora_fix', 0, '409.61 -3197.35 4269.03', '883.64 -2946.44 4397.03');
INSERT INTO "main"."game_zones" VALUES ('surf_plethora_fix', 1, '6989.35 -3892.38 -14815.97', '9428.60 -2250.78 -14687.97');
INSERT INTO "main"."game_zones" VALUES ('surf_prelude_ksf', 0, '-12385.07 12547.39 13088.03', '-12080.03 13056.52 13216.03');
INSERT INTO "main"."game_zones" VALUES ('surf_prelude_ksf', 1, '1072.03 -462.52 -4447.97', '1998.25 463.97 -4191.20');
INSERT INTO "main"."game_zones" VALUES ('surf_primero', 0, '10768.03 -2928.00 4864.03', '12271.97 -2550.43 4992.03');
INSERT INTO "main"."game_zones" VALUES ('surf_primero', 1, '-6111.84 -10736.00 -13183.97', '-5109.29 -8593.36 -12450.04');
INSERT INTO "main"."game_zones" VALUES ('surf_psycho', 0, '-201.27 -223.54 -313.93', '-2.01 89.21 -185.93');
INSERT INTO "main"."game_zones" VALUES ('surf_pyrism_njv', 0, '3148.98 -241.82 768.03', '3368.31 241.50 896.03');
INSERT INTO "main"."game_zones" VALUES ('surf_pyrism_njv', 1, '-10051.35 -6510.93 -279.97', '-9793.12 -5776.03 -59.37');
INSERT INTO "main"."game_zones" VALUES ('surf_quasar_final', 0, '-371.78 -473.97 16.03', '-139.09 -263.05 144.03');
INSERT INTO "main"."game_zones" VALUES ('surf_quilavar', 0, '-876.10 -78.65 6224.87', '-761.23 105.93 6385.85');
INSERT INTO "main"."game_zones" VALUES ('surf_quilavar', 1, '5296.03 14367.05 -15323.97', '6030.59 14807.82 -15086.90');
INSERT INTO "main"."game_zones" VALUES ('surf_rookie', 0, '-1380.08 10978.05 13680.03', '-1278.16 11354.21 13808.03');
INSERT INTO "main"."game_zones" VALUES ('surf_rookie', 1, '-2512.00 12560.03 2816.03', '-1550.23 13802.05 3360.64');
INSERT INTO "main"."game_zones" VALUES ('surf_sandman_v2', 0, '-476.68 -6571.16 3096.98', '-114.98 -5846.03 3413.91');
INSERT INTO "main"."game_zones" VALUES ('surf_sandman_v2', 1, '6206.99 4323.07 -671.97', '6455.97 4894.61 -396.81');
INSERT INTO "main"."game_zones" VALUES ('surf_savant_njv', 0, '160.04 -7951.74 1888.03', '386.26 -7631.04 2016.03');
INSERT INTO "main"."game_zones" VALUES ('surf_savant_njv', 1, '14393.87 13245.94 -3233.47', '14579.88 14289.08 -2870.65');
INSERT INTO "main"."game_zones" VALUES ('surf_sci_fi', 0, '11632.03 2744.03 5010.53', '12111.97 3000.85 5138.53');
INSERT INTO "main"."game_zones" VALUES ('surf_sci_fi', 1, '13820.38 -12431.97 624.03', '14219.08 -11441.66 911.14');
INSERT INTO "main"."game_zones" VALUES ('surf_sempar_njv', 0, '5320.00 -1499.22 -1985.97', '5600.03 -736.86 -1857.97');
INSERT INTO "main"."game_zones" VALUES ('surf_sempar_njv', 1, '3305.54 -11160.00 -13089.97', '3793.58 -10623.69 -12439.35');
INSERT INTO "main"."game_zones" VALUES ('surf_sh', 0, '-5431.97 -3727.97 6144.03', '-4987.16 -2992.09 6272.03');
INSERT INTO "main"."game_zones" VALUES ('surf_smile_njv', 0, '-7031.35 4511.74 1747.43', '-6847.97 4695.91 1936.03');
INSERT INTO "main"."game_zones" VALUES ('surf_smile_njv', 1, '-2607.97 -11375.97 384.03', '-2307.73 -9364.07 746.84');
INSERT INTO "main"."game_zones" VALUES ('surf_stonework', 0, '1102.22 -1237.06 3360.03', '1390.66 -784.25 3488.03');
INSERT INTO "main"."game_zones" VALUES ('surf_stonework', 1, '1252.70 10276.39 -11999.97', '1440.06 12893.49 -10289.72');
INSERT INTO "main"."game_zones" VALUES ('surf_stonework2', 0, '12429.75 -431.97 12656.03', '12702.35 431.97 12784.03');
INSERT INTO "main"."game_zones" VALUES ('surf_stonework2', 1, '-11949.91 -431.97 -10975.97', '-11311.24 424.70 -10431.39');
INSERT INTO "main"."game_zones" VALUES ('surf_stonework3', 0, '-4047.39 -7135.85 5152.03', '-3646.51 -6857.86 5280.03');
INSERT INTO "main"."game_zones" VALUES ('surf_stonework3', 1, '2576.03 14017.13 3712.03', '3562.06 14365.19 4180.89');
INSERT INTO "main"."game_zones" VALUES ('surf_sundown_njv', 0, '-4687.97 -943.97 14784.03', '-3904.27 1071.97 14912.03');
INSERT INTO "main"."game_zones" VALUES ('surf_sundown_njv', 1, '-12032.23 -2976.82 -7423.97', '-11200.08 -1247.73 -7295.97');
INSERT INTO "main"."game_zones" VALUES ('surf_syria', 0, '-5250.45 3426.36 -1181.97', '-4866.64 4132.30 -1053.97');
INSERT INTO "main"."game_zones" VALUES ('surf_tensile_njv', 0, '-12685.58 3828.53 10746.92', '-12519.22 4607.77 10895.53');
INSERT INTO "main"."game_zones" VALUES ('surf_tensile_njv', 1, '1140.03 3728.03 -10954.97', '2127.97 4719.97 -10826.97');
INSERT INTO "main"."game_zones" VALUES ('surf_thembrium_njv', 0, '-1915.66 2703.10 -480.97', '-888.43 3102.97 -352.97');
INSERT INTO "main"."game_zones" VALUES ('surf_thembrium_njv', 1, '8041.03 14697.95 4546.03', '10056.99 14931.80 4674.03');
INSERT INTO "main"."game_zones" VALUES ('surf_torque', 0, '3915.50 780.37 2844.03', '4078.18 956.24 2972.03');
INSERT INTO "main"."game_zones" VALUES ('surf_tronic_njv', 0, '-174.76 -175.38 11181.56', '174.94 174.43 11309.81');
INSERT INTO "main"."game_zones" VALUES ('surf_tronic_njv', 1, '-1479.23 -1479.70 -15214.09', '1478.83 1476.73 -14780.29');
INSERT INTO "main"."game_zones" VALUES ('surf_unusual_njv', 0, '-7007.44 2367.31 1280.03', '-5986.59 2637.60 1408.03');
INSERT INTO "main"."game_zones" VALUES ('surf_zion', 0, '-157.48 289.36 640.03', '155.84 496.00 768.03');
INSERT INTO "main"."game_zones" VALUES ('surf_calamity_njv', 0, '2558.03 -1648.97 -4890.97', '3748.98 -1004.00 -4762.97');
INSERT INTO "main"."game_zones" VALUES ('surf_calamity_njv', 1, '7529.57 -3579.24 -10735.97', '10196.47 -2587.40 -10607.97');
INSERT INTO "main"."game_zones" VALUES ('surf_calamity2', 0, '-1974.97 7046.03 2605.03', '-784.03 7680.32 2733.03');
INSERT INTO "main"."game_zones" VALUES ('surf_calamity2', 1, '-5265.73 -13314.99 -8095.97', '-4198.24 -10656.03 -6509.54');
INSERT INTO "main"."game_zones" VALUES ('surf_unusual_njv', 1, '4694.02 -9312.24 -1156.65', '6380.74 -8941.30 -779.97');
INSERT INTO "main"."game_zones" VALUES ('surf_lt_omnific', 2, '960.12 7104.95 -3807.97', '1087.95 7233.09 -3679.97');
INSERT INTO "main"."game_zones" VALUES ('surf_lt_omnific', 3, '704.72 6847.98 -11487.97', '1343.10 7487.91 -11359.97');
INSERT INTO "main"."game_zones" VALUES ('surf_adtr_njv', 3, '1822.23 -4697.78 -1504.97', '1951.89 -4638.74 -1376.97');
INSERT INTO "main"."game_zones" VALUES ('surf_adtr_njv', 2, '-2514.36 -4425.30 -692.06', '-2468.46 -4380.52 -564.06');
INSERT INTO "main"."game_zones" VALUES ('surf_mushroom_ksf', 2, '1993.99 -316.82 12168.03', '2325.40 317.18 12296.03');
INSERT INTO "main"."game_zones" VALUES ('surf_mushroom_ksf', 3, '-4666.08 -2520.42 7932.03', '-4187.98 -2075.02 8060.03');
INSERT INTO "main"."game_zones" VALUES ('surf_mushroom_ksf', 3, '-4656.67 2065.48 7932.03', '-4199.01 2536.49 8060.03');
INSERT INTO "main"."game_zones" VALUES ('surf_mushroom_ksf', 1, '-2428.83 -2792.68 -12152.56', '-2323.47 -2467.96 -12019.40');
INSERT INTO "main"."game_zones" VALUES ('surf_mushroom_ksf', -20, '-2324.74 2782.34 -12159.40', '-2324.74 2782.34 -12031.40');
INSERT INTO "main"."game_zones" VALUES ('surf_mushroom_ksf', 1, '-2426.67 2462.59 -12149.00', '-2322.86 2781.34 -12020.99');
INSERT INTO "main"."game_zones" VALUES ('surf_2012_njv', 2, '2480.08 -5568.09 4064.03', '2530.32 -5504.84 4192.03');
INSERT INTO "main"."game_zones" VALUES ('surf_2012_njv', 3, '7170.27 -5565.12 -5936.24', '7262.08 -5506.66 -5794.04');
INSERT INTO "main"."game_zones" VALUES ('surf_sinsane_ksf', 2, '14623.60 672.31 960.03', '15327.88 1376.53 1088.03');
INSERT INTO "main"."game_zones" VALUES ('surf_sinsane_ksf', 3, '15416.34 1461.57 -3487.97', '15471.97 1519.97 -3249.09');
INSERT INTO "main"."game_zones" VALUES ('surf_pyrism_njv', 2, '-6982.55 -5904.19 851.33', '-6949.29 -5858.32 979.33');
INSERT INTO "main"."game_zones" VALUES ('surf_nightmare', 2, '4802.03 -6453.97 2365.74', '5219.12 -5758.01 2496.03');
INSERT INTO "main"."game_zones" VALUES ('surf_nightmare', 3, '11367.98 -6225.67 1889.21', '11507.32 -5962.65 2114.61');
INSERT INTO "main"."game_zones" VALUES ('surf_methadone', 2, '8976.03 5368.03 11747.93', '9515.25 6615.97 11882.13');
INSERT INTO "main"."game_zones" VALUES ('surf_methadone', 3, '12112.03 5551.51 1771.13', '12467.37 6433.38 1899.13');
INSERT INTO "main"."game_zones" VALUES ('surf_methadone', 3, '6918.73 5548.29 1774.13', '7279.97 6427.46 1902.13');
INSERT INTO "main"."game_zones" VALUES ('surf_4dimensional', 3, '-14789.32 -10007.22 -6458.34', '-14135.52 -9371.60 -6330.34');
INSERT INTO "main"."game_zones" VALUES ('surf_4dimensional', 2, '15005.50 7026.04 5575.13', '15455.39 8527.55 5710.38');
INSERT INTO "main"."game_zones" VALUES ('surf_calamity2', 2, '2457.75 -10939.42 -3531.44', '2498.70 -10884.91 -3403.44');
INSERT INTO "main"."game_zones" VALUES ('surf_calamity2', 3, '-5265.28 -13313.06 -8095.97', '-4198.15 -10656.03 -6514.10');
INSERT INTO "main"."game_zones" VALUES ('surf_sundown_njv', 1, '-12031.07 1377.13 -7423.97', '-11200.05 3104.43 -7295.97');
INSERT INTO "main"."game_zones" VALUES ('surf_kz_protraining', 2, '4360.69 -10207.97 1856.03', '4527.97 -9744.02 1984.03');
INSERT INTO "main"."game_zones" VALUES ('surf_kz_protraining', 3, '-1967.99 -9844.78 160.03', '-1936.00 -9740.88 288.03');
INSERT INTO "main"."game_zones" VALUES ('surf_faint_fix', 2, '9959.38 -5406.23 -4120.97', '10144.78 -4832.63 -3992.97');
INSERT INTO "main"."game_zones" VALUES ('surf_faint_fix', 3, '9154.17 -5204.35 -6279.88', '9189.64 -4989.12 -6144.73');
INSERT INTO "main"."game_zones" VALUES ('surf_heaven_njv', 2, '6785.24 -10220.97 -2039.97', '7551.12 -9809.84 -1911.97');
INSERT INTO "main"."game_zones" VALUES ('surf_heaven_njv', 3, '6786.15 -7905.24 -3415.97', '7552.97 -7498.36 -3287.97');
INSERT INTO "main"."game_zones" VALUES ('surf_auroria_ksf', 2, '-9115.21 -1438.19 1904.23', '-8635.84 -960.98 2036.77');
INSERT INTO "main"."game_zones" VALUES ('surf_auroria_ksf', 3, '-9131.47 -14718.97 -583.97', '-8621.38 -14256.33 -455.97');
INSERT INTO "main"."game_zones" VALUES ('surf_thembrium_njv', 2, '4641.66 -1099.54 2111.03', '5184.73 -44.78 2239.03');
INSERT INTO "main"."game_zones" VALUES ('surf_thembrium_njv', 3, '4804.46 -714.05 -4930.57', '5085.92 -428.48 -4785.54');
INSERT INTO "main"."game_zones" VALUES ('surf_savant_njv', 2, '-13699.50 4813.74 1882.33', '-13516.35 4973.94 2012.86');
INSERT INTO "main"."game_zones" VALUES ('surf_savant_njv', 3, '-14410.38 14637.02 -1319.97', '-12807.47 14837.28 -1191.97');
INSERT INTO "main"."game_zones" VALUES ('surf_plethora_fix', 2, '-969.91 -3194.63 4269.00', '-655.51 -2947.67 4397.03');
INSERT INTO "main"."game_zones" VALUES ('surf_plethora_fix', 3, '6689.22 -4613.34 -11664.77', '9766.07 -1533.96 -11523.28');
INSERT INTO "main"."game_zones" VALUES ('surf_creation', 2, '-7307.52 23.81 6017.03', '-6967.76 523.09 6145.03');
INSERT INTO "main"."game_zones" VALUES ('surf_creation', 3, '-8117.69 116.51 4400.03', '-8036.81 426.89 4528.03');
INSERT INTO "main"."game_zones" VALUES ('surf_inrage2', 2, '4857.83 -2634.73 6639.66', '7095.24 -2187.82 6768.11');
INSERT INTO "main"."game_zones" VALUES ('surf_inrage2', 3, '69.71 -103.97 -2315.16', '393.67 225.33 -2160.83');
INSERT INTO "main"."game_zones" VALUES ('surf_happyhands', 2, '6353.04 -10148.51 10480.05', '6849.12 -10016.00 10612.03');
INSERT INTO "main"."game_zones" VALUES ('surf_happyhands', 3, '6221.81 -5517.68 7564.03', '6972.93 -5040.21 7700.03');
INSERT INTO "main"."game_zones" VALUES ('surf_lessons', 2, '3060.03 -8914.88 280.03', '3411.97 -8664.03 412.03');
INSERT INTO "main"."game_zones" VALUES ('surf_lessons', 3, '3188.03 -10013.57 -1159.97', '3283.97 -9543.32 -1031.97');
INSERT INTO "main"."game_zones" VALUES ('surf_stonework2', 2, '13125.67 5712.00 5632.03', '13407.97 6575.97 5760.03');
INSERT INTO "main"."game_zones" VALUES ('surf_stonework2', 3, '-12767.98 5712.00 5632.03', '-12396.17 6575.97 5760.03');
INSERT INTO "main"."game_zones" VALUES ('surf_aircontrol_ksf', 0, '-2895.97 -10127.97 14336.03', '-816.03 -9261.37 14464.03');
INSERT INTO "main"."game_zones" VALUES ('surf_akai_final', 0, '-12748.97 8820.05 1480.03', '-12677.69 9012.29 1608.03');
INSERT INTO "main"."game_zones" VALUES ('surf_and_destroy', 0, '9329.25 13384.03 7498.03', '9768.23 13759.97 7626.03');
INSERT INTO "main"."game_zones" VALUES ('surf_and_destroy', 1, '9774.40 1139.93 -4913.97', '10026.72 1236.32 -4785.97');
INSERT INTO "main"."game_zones" VALUES ('surf_and_destroy', 2, '2572.05 -3336.97 -1865.97', '2678.97 -3177.03 -1737.97');
INSERT INTO "main"."game_zones" VALUES ('surf_and_destroy', 3, '-4517.97 -3740.97 4727.03', '-4384.00 -3537.03 4855.03');
INSERT INTO "main"."game_zones" VALUES ('surf_dionysus', 0, '-167.48 -83.98 16.03', '-92.92 92.50 144.03');
INSERT INTO "main"."game_zones" VALUES ('surf_dionysus', 1, '10032.03 -87.10 -4655.97', '10063.97 87.42 -4527.97');
INSERT INTO "main"."game_zones" VALUES ('surf_forbidden_ways_ksf', 0, '-189.62 -10895.31 6336.03', '215.79 -10069.70 6464.03');
INSERT INTO "main"."game_zones" VALUES ('surf_forbidden_ways_ksf', 1, '10308.24 8548.15 -3311.97', '10544.00 9450.13 -3179.97');
INSERT INTO "main"."game_zones" VALUES ('surf_funhouse_njv', 0, '-8239.96 13144.03 14304.03', '-7933.09 13766.66 14435.97');
INSERT INTO "main"."game_zones" VALUES ('surf_funhouse_njv', 1, '754.03 -2776.58 32.03', '1455.97 -2115.34 160.03');
INSERT INTO "main"."game_zones" VALUES ('surf_forbidden_ways_ksf', 2, '9744.03 2448.03 -1023.97', '10031.74 2745.88 -895.97');
INSERT INTO "main"."game_zones" VALUES ('surf_forbidden_ways_ksf', 3, '-9520.15 3680.03 -4083.23', '-9232.03 4719.97 -3839.98');
INSERT INTO "main"."game_zones" VALUES ('surf_placid', 3, '9249.51 5359.79 -3263.97', '10011.51 6128.55 -3016.24');
INSERT INTO "main"."game_zones" VALUES ('surf_placid', 2, '5193.49 5568.03 -2603.97', '5309.97 5871.97 -2427.97');
INSERT INTO "main"."game_zones" VALUES ('surf_6', 2, '-1786.43 13384.79 12368.03', '-1636.73 13560.39 12496.03');
INSERT INTO "main"."game_zones" VALUES ('surf_6', 3, '6436.96 13138.27 11952.03', '6663.01 13620.23 12080.03');

-- ----------------------------
-- Table structure for gmod_admins
-- ----------------------------
DROP TABLE IF EXISTS "main"."gmod_admins";
CREATE TABLE "gmod_admins" (
"nID"  INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
"szSteam"  TEXT NOT NULL,
"nLevel"  INTEGER NOT NULL DEFAULT 0,
"nType"  INTEGER NOT NULL DEFAULT 0
);

-- ----------------------------
-- Records of gmod_admins
-- ----------------------------

-- ----------------------------
-- Table structure for gmod_bans
-- ----------------------------
DROP TABLE IF EXISTS "main"."gmod_bans";
CREATE TABLE "gmod_bans" (
"nID"  INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
"szUserSteam"  TEXT NOT NULL,
"szUserName"  TEXT DEFAULT NULL,
"nStart"  TEXT NOT NULL,
"nLength"  INTEGER NOT NULL,
"szReason"  TEXT DEFAULT NULL,
"szAdminSteam"  TEXT NOT NULL,
"szAdminName"  TEXT DEFAULT NULL
);

-- ----------------------------
-- Records of gmod_bans
-- ----------------------------

-- ----------------------------
-- Table structure for gmod_logging
-- ----------------------------
DROP TABLE IF EXISTS "main"."gmod_logging";
CREATE TABLE "gmod_logging" (
"nID"  INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
"nType"  INTEGER NOT NULL DEFAULT 0,
"szData"  TEXT,
"szDate"  TEXT DEFAULT NULL,
"szAdminSteam"  TEXT NOT NULL,
"szAdminName"  TEXT DEFAULT NULL
);

-- ----------------------------
-- Records of gmod_logging
-- ----------------------------

-- ----------------------------
-- Table structure for gmod_notifications
-- ----------------------------
DROP TABLE IF EXISTS "main"."gmod_notifications";
CREATE TABLE "gmod_notifications" (
"nID"  INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
"nType"  INTEGER NOT NULL DEFAULT 0,
"nTimeout"  INTEGER NOT NULL DEFAULT 60,
"szText"  TEXT DEFAULT NULL
);

-- ----------------------------
-- Records of gmod_notifications
-- ----------------------------

-- ----------------------------
-- Table structure for gmod_vips
-- ----------------------------
DROP TABLE IF EXISTS "main"."gmod_vips";
CREATE TABLE "gmod_vips" (
"nID"  INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
"szSteam"  TEXT NOT NULL,
"nType"  INTEGER NOT NULL,
"szTag"  TEXT,
"szName"  TEXT,
"szChat"  TEXT,
"nStart"  TEXT,
"nLength"  INTEGER
);