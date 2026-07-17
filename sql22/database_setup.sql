-- =====================================================
-- AK Jumper Bot — Complete Database Setup
-- ينشئ كل الجداول ويدخل كل البيانات اللازمة للبوت
-- آمن للتشغيل مرات متعددة (DROP + CREATE)
-- =====================================================

-- =====================================================
-- 1. حذف الجداول القديمة (بالترتيب الصحيح)
-- =====================================================
DROP TABLE IF EXISTS payment_requests;
DROP TABLE IF EXISTS subscriptions;
DROP TABLE IF EXISTS subscription_plans;
DROP TABLE IF EXISTS payment_settings;
DROP TABLE IF EXISTS farm_tasks;
DROP TABLE IF EXISTS events_singular;
DROP TABLE IF EXISTS events_af;
DROP TABLE IF EXISTS events_adj;
DROP TABLE IF EXISTS games_singular;
DROP TABLE IF EXISTS games_af;
DROP TABLE IF EXISTS games_adj;
DROP TABLE IF EXISTS proxies;
DROP TABLE IF EXISTS allowed_users;
DROP TABLE IF EXISTS user_platform;
DROP TABLE IF EXISTS users;

-- =====================================================
-- 2. إنشاء الجداول
-- =====================================================

CREATE TABLE users (
    user_id         BIGINT PRIMARY KEY,
    username        TEXT,
    name            TEXT,
    admin           INTEGER NOT NULL DEFAULT 0,
    allowed         INTEGER NOT NULL DEFAULT 0,
    banned          INTEGER NOT NULL DEFAULT 0,
    created_at      TEXT,
    last_use        TEXT,
    total_requests  INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE allowed_users (
    user_id    BIGINT PRIMARY KEY,
    username   TEXT,
    name       TEXT,
    added_by   BIGINT,
    added_date TEXT
);

CREATE TABLE user_platform (
    user_id  BIGINT PRIMARY KEY,
    platform TEXT NOT NULL DEFAULT 'android'
);

CREATE TABLE proxies (
    id         SERIAL PRIMARY KEY,
    user_id    BIGINT UNIQUE NOT NULL,
    proxy_type TEXT NOT NULL DEFAULT 'http',
    host       TEXT NOT NULL,
    port       INTEGER NOT NULL,
    username   TEXT NOT NULL DEFAULT '',
    password   TEXT NOT NULL DEFAULT ''
);

-- AppsFlyer
CREATE TABLE games_af (
    id           SERIAL PRIMARY KEY,
    name         TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    package      TEXT NOT NULL,
    dev_key      TEXT NOT NULL,
    emoji        TEXT NOT NULL DEFAULT '🎮'
);

CREATE TABLE events_af (
    id           SERIAL PRIMARY KEY,
    game_id      INTEGER NOT NULL REFERENCES games_af(id) ON DELETE CASCADE,
    event_name   TEXT NOT NULL,
    display_name TEXT NOT NULL,
    event_type   TEXT NOT NULL DEFAULT 'level',
    revenue      REAL,
    level_value  INTEGER,
    UNIQUE(game_id, event_name)
);

-- Singular
CREATE TABLE games_singular (
    id           SERIAL PRIMARY KEY,
    name         TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    package      TEXT NOT NULL,
    app_key      TEXT NOT NULL,
    emoji        TEXT NOT NULL DEFAULT '🎮'
);

CREATE TABLE events_singular (
    id           SERIAL PRIMARY KEY,
    game_id      INTEGER NOT NULL REFERENCES games_singular(id) ON DELETE CASCADE,
    event_name   TEXT NOT NULL,
    display_name TEXT NOT NULL,
    event_type   TEXT NOT NULL DEFAULT 'level',
    level_value  INTEGER,
    UNIQUE(game_id, event_name)
);

-- Adjust
CREATE TABLE games_adj (
    id           SERIAL PRIMARY KEY,
    name         TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    app_token    TEXT NOT NULL,
    emoji        TEXT NOT NULL DEFAULT '🎮'
);

CREATE TABLE events_adj (
    id           SERIAL PRIMARY KEY,
    game_id      INTEGER NOT NULL REFERENCES games_adj(id) ON DELETE CASCADE,
    event_name   TEXT NOT NULL,
    event_token  TEXT NOT NULL,
    display_name TEXT NOT NULL,
    level_value  INTEGER DEFAULT 0,
    UNIQUE(game_id, event_name)
);

-- Farm tasks
CREATE TABLE farm_tasks (
    id            SERIAL PRIMARY KEY,
    user_id       BIGINT NOT NULL,
    task_name     TEXT NOT NULL,
    platform      TEXT NOT NULL,
    game_id       INTEGER NOT NULL,
    game_name     TEXT NOT NULL,
    start_level   INTEGER NOT NULL,
    end_level     INTEGER NOT NULL,
    total_days    INTEGER NOT NULL,
    mode          TEXT NOT NULL DEFAULT 'normal',
    current_day   INTEGER NOT NULL DEFAULT 1,
    current_level INTEGER NOT NULL,
    status        TEXT NOT NULL DEFAULT 'running',
    created_date  TEXT,
    aifa          TEXT NOT NULL DEFAULT '',
    gaid          TEXT NOT NULL DEFAULT '',
    af_uid        TEXT NOT NULL DEFAULT '',
    gps_adid      TEXT NOT NULL DEFAULT '',
    idfa          TEXT NOT NULL DEFAULT '',
    idfv          TEXT NOT NULL DEFAULT '',
    singular_uid  TEXT NOT NULL DEFAULT ''
);

-- Subscription Plans
CREATE TABLE subscription_plans (
    id            SERIAL PRIMARY KEY,
    name          TEXT NOT NULL,
    duration_days INTEGER NOT NULL,
    price         DECIMAL(10,2) NOT NULL,
    daily_limit   INTEGER NOT NULL,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP DEFAULT NOW()
);

-- Subscriptions
CREATE TABLE subscriptions (
    id               SERIAL PRIMARY KEY,
    user_id          BIGINT NOT NULL,
    plan_id          INTEGER REFERENCES subscription_plans(id),
    plan_name        TEXT NOT NULL DEFAULT '',
    daily_limit      INTEGER NOT NULL DEFAULT 10,
    daily_used       INTEGER DEFAULT 0,
    last_reset_date  DATE DEFAULT CURRENT_DATE,
    start_date       TIMESTAMP NOT NULL DEFAULT NOW(),
    end_date         TIMESTAMP NOT NULL,
    status           TEXT DEFAULT 'active',
    created_at       TIMESTAMP DEFAULT NOW()
);

-- Payment Settings
CREATE TABLE payment_settings (
    id               SERIAL PRIMARY KEY,
    method           TEXT UNIQUE NOT NULL,
    display_name     TEXT NOT NULL,
    address          TEXT DEFAULT '',
    instructions     TEXT DEFAULT '',
    is_active        BOOLEAN DEFAULT TRUE,
    binance_api_key  TEXT DEFAULT '',
    binance_api_secret TEXT DEFAULT '',
    updated_at       TIMESTAMP DEFAULT NOW()
);

-- Payment Requests
CREATE TABLE payment_requests (
    id              SERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL,
    user_name       TEXT DEFAULT '',
    user_username   TEXT DEFAULT '',
    plan_id         INTEGER REFERENCES subscription_plans(id),
    plan_name       TEXT NOT NULL DEFAULT '',
    method          TEXT NOT NULL,
    amount          DECIMAL(10,2) NOT NULL DEFAULT 0,
    transaction_id  TEXT DEFAULT '',
    proof_file_id   TEXT DEFAULT '',
    status          TEXT DEFAULT 'pending',
    admin_id        BIGINT,
    created_at      TIMESTAMP DEFAULT NOW(),
    processed_at    TIMESTAMP
);

-- =====================================================
-- 3. الفهارس (Indexes)
-- =====================================================
CREATE INDEX idx_users_allowed        ON users(allowed);
CREATE INDEX idx_users_banned         ON users(banned);
CREATE INDEX idx_user_platform        ON user_platform(user_id);
CREATE INDEX idx_proxies_user          ON proxies(user_id);
CREATE INDEX idx_events_af_game        ON events_af(game_id);
CREATE INDEX idx_events_singular_game  ON events_singular(game_id);
CREATE INDEX idx_events_adj_game       ON events_adj(game_id);
CREATE INDEX idx_farm_tasks_user       ON farm_tasks(user_id);
CREATE INDEX idx_farm_tasks_status     ON farm_tasks(status);
CREATE INDEX idx_subscriptions_user    ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status  ON subscriptions(status);
CREATE INDEX idx_subscriptions_end     ON subscriptions(end_date);
CREATE INDEX idx_pay_requests_status   ON payment_requests(status);
CREATE INDEX idx_pay_requests_user     ON payment_requests(user_id);

-- =====================================================
-- 4. بيانات المديرين الافتراضيين
-- =====================================================
INSERT INTO users(user_id,username,name,admin,allowed,created_at) VALUES
(6075014046,'admin','Admin',1,1,NOW()::TEXT),
(5697154046,'admin2','Admin2',1,1,NOW()::TEXT),
(8114043468,'admin3','Admin3',1,1,NOW()::TEXT);

INSERT INTO allowed_users(user_id,username,name,added_by,added_date) VALUES
(6075014046,'admin','Admin',6075014046,NOW()::TEXT),
(5697154046,'admin2','Admin2',6075014046,NOW()::TEXT),
(8114043468,'admin3','Admin3',6075014046,NOW()::TEXT);

INSERT INTO user_platform(user_id,platform) VALUES
(6075014046,'android'),
(5697154046,'android'),
(8114043468,'android');

-- =====================================================
-- 5. ألعاب AppsFlyer (dev_key كامل)
-- =====================================================
INSERT INTO games_af(name,display_name,package,dev_key,emoji) VALUES
('dice_dream',         '🎲 Dice Dreams',         'com.superplaystudios.dicedreams',              'Hn5qYjVAaRNJYDcwF4LaWF',       '🎲'),
('domino_dreams',      '🃏 Domino Dreams',        'com.screenshake.dominodreams',                 'Hn5qYjVAaRNJYDcwF4LaWF',       '🃏'),
('buzzle_chaos',       '🎲 Buzzle Chaos',         'com.global.pnck',                              'ZnhUvonKa6qF9xhgt7GcBQ',       '🎲'),
('coin_master',        '🎲 Coin Master',          'com.moonactive.coinmaster',                    'H3KjoCRVTiVgA5mWSAHtCe',       '🎲'),
('royal_match',        '👑 Royal Match',          'com.dreamgames.royalmatch',                    'B27HnbGEcbWC2fv79DDhcb',       '👑'),
('merge_gardens',      '🌺 Merge Gardens',        'com.futureplay.mergematch',                    'nr8SibwpFjcKGBQNpDdttd',       '🌺'),
('highroller_vegas',   '🎲 HIGHROLLER Vegas',     'com.lynxgames.hrv',                            'sSpBC5SKPKEV8fbZJgw6vM',       '🎲'),
('rock_n_cash',        '💰 Rock N Cash Casino',   'net.flysher.rockncash',                        'W5VWPj5fbCGABtk59TsmJQ',       '💰'),
('coinchef',           '🍳 COINCHEF',             'com.FortuneMine.CuisineMaster',                'im6mgZbZJsHKGVowkkxkGm',       '🍳'),
('blackjack21',        '🃏 Blackjack 21',         'com.kamagames.blackjack',                      'YbczyDZZmXbxwpYYyJgqTQ',       '🃏'),
('sunshine_island',    '🏝️ Sunshine Island',     'com.newmoonproduction.sunshineisland',         'FtaT5WH9rMJjJkMd4LfBCT',       '🏝️'),
('farmville3',         '🌾 Farmville 3',          'com.zynga.FarmVille2CountryEscape',            '438VCPmX2ZLYvsDPfGLZXb',       '🌾'),
('disney_solitaire',   '🎲 Disney Solitaire',     'com.superplaystudios.disneysolitairedreams',   'Hn5qYjVAaRNJYDcwF4LaWF',       '🎲'),
('matching_story',     '🎲 Matching Story',       'com.joycastle.mergematch',                     'v2w2tuNCNaBNXvFJgRGPRW',       '🎲'),
('nations_of_darkness','🎲 Nations of Darkness',  'com.allstarunion.nod',                         'x88hdqNmd8vALRmRMhgY4Q',       '🎲'),
('hero_wars',          '🎲 Hero Wars',            'com.nexters.herowars',                         'MGPcVAUzD9XqbwAY6q7KMf',       '🎲'),
('zombie_waves',       '🧟 Zombie Waves',         'com.ddup.zombiewaves.zw',                      'wiQMRPvGaAYTGBCgM5yN9N',       '🧟');

-- =====================================================
-- 6. أحداث AppsFlyer
-- =====================================================

-- Dice Dreams
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_af WHERE name='dice_dream';
  INSERT INTO events_af(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'af_kingdom_3_restored', '🏰 Kingdom 3',  'kingdom', 3),
    (gid,'af_kingdom_18_restored','🏰 Kingdom 18', 'kingdom', 18);
END $$;

-- Domino Dreams
DO $$ DECLARE gid INT; i INT; BEGIN
  SELECT id INTO gid FROM games_af WHERE name='domino_dreams';
  FOR i IN 1..15 LOOP
    INSERT INTO events_af(game_id,event_name,display_name,event_type,level_value)
    VALUES (gid,'af_area_'||i||'_completed','🗺️ Area '||i,'level',i);
  END LOOP;
  INSERT INTO events_af(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'af_level_100_completed','🏆 Level 100','level',100);
END $$;

-- Royal Match
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_af WHERE name='royal_match';
  INSERT INTO events_af(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'af_level_5_completed',   '⭐ Level 5',   'level', 5),
    (gid,'af_level_10_completed',  '⭐ Level 10',  'level', 10),
    (gid,'af_level_25_completed',  '⭐ Level 25',  'level', 25),
    (gid,'af_level_50_completed',  '⭐ Level 50',  'level', 50),
    (gid,'af_level_100_completed', '⭐ Level 100', 'level', 100);
END $$;

-- Merge Gardens
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_af WHERE name='merge_gardens';
  INSERT INTO events_af(game_id,event_name,display_name,event_type,revenue) VALUES
    (gid,'Incent_Player_Level_Up_2','⭐ Player Level Up 2','level',NULL),
    (gid,'Incent_IAP_gems2',        '💎 IAP Gems 2',       'purchase',0.99);
END $$;

-- HIGHROLLER Vegas
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_af WHERE name='highroller_vegas';
  INSERT INTO events_af(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'app_level_achieved_5','🎯 Level 5','level',5);
END $$;

-- Rock N Cash
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_af WHERE name='rock_n_cash';
  INSERT INTO events_af(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'v3_rnc_level_up_10_S2S','🎰 Level Up 10','level',10);
END $$;

-- COINCHEF
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_af WHERE name='coinchef';
  INSERT INTO events_af(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'level2_completed','🍳 Level 2 Completed','level',2);
END $$;

-- Blackjack 21
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_af WHERE name='blackjack21';
  INSERT INTO events_af(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'af_level_5_completed',  '⭐ Level 5',  'level', 5),
    (gid,'af_level_10_completed', '⭐ Level 10', 'level', 10),
    (gid,'af_level_20_completed', '⭐ Level 20', 'level', 20);
END $$;

-- Sunshine Island
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_af WHERE name='sunshine_island';
  INSERT INTO events_af(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'af_level5_achieved','🏝️ Level 5','level',5);
END $$;

-- Farmville 3
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_af WHERE name='farmville3';
  INSERT INTO events_af(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'Player_Level9','⭐ Level 9','level',9);
END $$;

-- Coin Master
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_af WHERE name='coin_master';
  INSERT INTO events_af(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'village_1_complete','🏠 Village 1 Complete','level',1);
END $$;

-- Disney Solitaire
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_af WHERE name='disney_solitaire';
  INSERT INTO events_af(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'af_level_100_completed','⭐ Level 100','level',100),
    (gid,'af_area_22_completed',  '🗺️ Area 22', 'area',22);
END $$;

-- Hero Wars
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_af WHERE name='hero_wars';
  INSERT INTO events_af(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'af_level_10_completed','⭐ Level 10','level',10),
    (gid,'af_level_25_completed','⭐ Level 25','level',25);
END $$;

-- Zombie Waves
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_af WHERE name='zombie_waves';
  INSERT INTO events_af(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'af_level_10_completed','🧟 Level 10','level',10),
    (gid,'af_level_20_completed','🧟 Level 20','level',20);
END $$;

-- =====================================================
-- 7. ألعاب Singular (app_key كامل)
-- =====================================================
INSERT INTO games_singular(name,display_name,package,app_key,emoji) VALUES
('animals_coins',   '🦁 Animals & Coins',     'com.innplaylabs.animalkingdomraid',  'innplay_labs_33d87c9b',    '🦁'),
('time_master',     '⏰ Time Master',          'com.firefog.timemaster',             'myappfree_spa_38e49215',   '⏰'),
('beast_go',        '🐉 Beast Go',             'com.ninthart.board.beastgo',         'myappfree_spa_38e49215',   '🐉'),
('coin_fantasy',    '💰 Coin Fantasy',         'com.okvision.coinfantasy',           'myappfree_spa_38e49215',   '💰'),
('dragon_farm',     '🐉 Dragon Farm',          'com.dragon.escape.island.adventure', 'myappfree_spa_38e49215',   '🐉'),
('box_cat_jam',     '🐱 Box Cat Jam',          'com.actionfit.blockcat',             'actionfit_adc62229',       '🐱'),
('idle_soap',       '🧼 Idle Soap ASMR',       'games.midnite.isa',                  'myappfree_spa_38e49215',   '🧼'),
('superheroes_idle','🦸 Superheroes Idle RPG', 'games.midnite.sid',                  'myappfree_spa_38e49215',   '🦸'),
('survivor_idle',   '🏃 Survivor Idle Run',    'games.midnite.sri',                  'myappfree_spa_38e49215',   '🏃'),
('pop_slots',       '🎰 POP Slots',            'com.playstudios.popslots',           'playstudios_3852f898',     '🎰'),
('mgm_slots',       '🎰 MGM Slots Live',       'com.playstudios.showstar',           'playstudios_3852f898',     '🎰'),
('myvegas',         '🎰 myVEGAS Slots',        'com.playstudios.myvegas',            'playstudios_3852f898',     '🎰'),
('power_spin',      '💪 Power Spin Quest',     'com.braingames.powerquest',          'brain_games_a7dde873',     '💪'),
('sweet_jam',       '🍯 Sweet Jam!',           'puzzle.game.sweetjam',               'myappfree_spa_38e49215',   '🍯'),
('matching_go',     '🔗 Matching Go!',         'com.matchinggo.puzzlegames',         'xinagyi_f4545a5d',         '🔗'),
('screw_out',       '🔧 Screw Out Factory 3D', 'com.ntt.screw.out.factory',          'puzzle_studios_4d38bec9',  '🔧'),
('hole_collect',    '🕳️ Hole Collect',         'com.ntt.hole.collect.objects',       'puzzle_studios_4d38bec9',  '🕳️'),
('tetris_block',    '🧩 Tetris Block Party',   'com.playstudios.tetrisblockparty',   'playstudios_3852f898',     '🧩'),
('word_madness',    '📖 Word Madness',         'com.word.madness',                   'brain_games_a7dde873',     '📖'),
('word_wise',       '📖 Word Wise',            'com.playx.wordwise.crossword',       'myappfree_spa_38e49215',   '📖'),
('eatventure',      '🍔 Eatventure',           'com.hwqgrhhjfd.idlefastfood',        'lessmore_edff53fc',        '🍔');

-- =====================================================
-- 8. أحداث Singular
-- =====================================================

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='animals_coins';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'sng_level_achieved','🦁 sng_level_achieved','level',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='time_master';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'mn_location_1','⏰ location 1','level',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='beast_go';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'sng_level_achieved','🐉 sng_level_achieved','level',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='coin_fantasy';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'mn_level_','💰 mn_level_','level',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='dragon_farm';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'mn_level_','🐉 mn_level_','level',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='box_cat_jam';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'First_attempt_level_','🐱 First_attempt_level_','level',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='idle_soap';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'soap_unlocked','🧼 soap_unlocked','unlock',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='superheroes_idle';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'mn_cheater_level_achieved','🦸 mn_cheater_level_achieved','level',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='survivor_idle';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'sng_level_achieved','🏃 sng_level_achieved','level',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='pop_slots';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'level','🎰 level','level',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='mgm_slots';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'level','🎰 level','level',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='myvegas';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'level','🎰 level','level',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='power_spin';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'level_ended_','💪 level_ended_','level',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='sweet_jam';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'sng_level_achieved','🍯 sng_level_achieved','level',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='matching_go';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'user_level_complete_1','🔗 user_level_complete_1','level',1),
    (gid,'user_level_complete_5','🔗 user_level_complete_5','level',5),
    (gid,'ad_show_','📺 ad_show_','ad',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='screw_out';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'sng_level_achieved','🔧 sng_level_achieved','level',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='hole_collect';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'map_unlocked',      '🗺️ map_unlocked',      'unlock',1),
    (gid,'sng_level_achieved','🕳️ sng_level_achieved','level',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='tetris_block';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'level_','🧩 level_','level',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='word_madness';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'_levels_completed','📖 _levels_completed','level',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='word_wise';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'mn_level_','📖 mn_level_','level',1);
END $$;

DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_singular WHERE name='eatventure';
  INSERT INTO events_singular(game_id,event_name,display_name,event_type,level_value) VALUES
    (gid,'restaurant_unlocked',     '🍔 restaurant_unlocked',     'unlock',1),
    (gid,'lm_restaurant_completion','🍔 lm_restaurant_completion', 'complete',1);
END $$;

-- =====================================================
-- 9. ألعاب Adjust
-- =====================================================
INSERT INTO games_adj(name,display_name,app_token,emoji) VALUES
('get_color',          '🎨 Get Color',              '367kicwptj5s','🎨'),
('merge_blocks',       '🔲 2048 X2 Merge Blocks',   '367kicwptj5s','🔲'),
('puzzle2248',         '🧩 2248 Puzzle',             '367kicwptj5s','🧩'),
('alice_blastland',    '🌸 Alice in Blastland',      '367kicwptj5s','🌸'),
('army_tycoon',        '🎖️ Army Tycoon',            '367kicwptj5s','🎖️'),
('battle_night',       '⚔️ Battle Night',           '367kicwptj5s','⚔️'),
('berry_factory',      '🍓 Berry Factory Tycoon',    '367kicwptj5s','🍓'),
('big_card_solitaire', '🃏 Big Card Solitaire',      '367kicwptj5s','🃏'),
('bingo_aloha',        '🍍 Bingo Aloha',             '367kicwptj5s','🍍'),
('bingo_showdown',     '🎯 Bingo Showdown',          '367kicwptj5s','🎯'),
('blast_friends',      '💥 Blast Friends',           '367kicwptj5s','💥'),
('block_blitz',        '🧱 Block Blitz',             '367kicwptj5s','🧱'),
('block_joy',          '🎮 Block Joy Puzzle',        '367kicwptj5s','🎮'),
('gems_adventure',     '💎 Gems Adventure',          '367kicwptj5s','💎'),
('bravo_slots',        '🎰 Bravo Classic Slots',     '367kicwptj5s','🎰'),
('cash_storm',         '🌪️ Cash Storm',             '367kicwptj5s','🌪️'),
('climb_mountain',     '⛰️ Climb the Mountain',     '367kicwptj5s','⛰️'),
('clock_maker',        '⏰ Clock Maker',             '367kicwptj5s','⏰'),
('clone_evolution',    '🧬 Clone Evolution',         '367kicwptj5s','🧬'),
('clubbillion',        '🎲 Clubbillion Vegas',       '367kicwptj5s','🎲'),
('color_water_sort',   '🎨 Color Water Sort',        '367kicwptj5s','🎨');

-- =====================================================
-- 10. أحداث Adjust (event_token كامل)
-- =====================================================

-- Get Color
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_adj WHERE name='get_color';
  INSERT INTO events_adj(game_id,event_name,event_token,display_name,level_value) VALUES
    (gid,'level_15',  '8t8nb3','🏆 Level 15',   15),
    (gid,'level_30',  'uwq9v8','🏆 Level 30',   30),
    (gid,'level_50',  'fdlgyk','🏆 Level 50',   50),
    (gid,'level_75',  'dwhyjz','🏆 Level 75',   75),
    (gid,'level_80',  '34vgez','🏆 Level 80',   80),
    (gid,'level_100', 'txq8if','🏆 Level 100', 100),
    (gid,'level_120', 'lwhvaj','🏆 Level 120', 120),
    (gid,'level_150', 'iatv2g','🏆 Level 150', 150),
    (gid,'level_200', 'stpy1k','🏆 Level 200', 200),
    (gid,'level_300', '53lena','🏆 Level 300', 300),
    (gid,'level_400', 'dbdy8l','🏆 Level 400', 400),
    (gid,'level_500', '3i4yf5','🏆 Level 500', 500),
    (gid,'level_700', 'pwd51u','🏆 Level 700', 700),
    (gid,'level_1000','4o9jbt','🏆 Level 1000',1000);
END $$;

-- 2048 X2 Merge Blocks
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_adj WHERE name='merge_blocks';
  INSERT INTO events_adj(game_id,event_name,event_token,display_name,level_value) VALUES
    (gid,'event_callback_yd6777','yd6777','Reach step 5',   5),
    (gid,'event_callback_8mpa1x','8mpa1x','Step 10',       10),
    (gid,'event_callback_j9tstz','j9tstz','Step 25',       25),
    (gid,'event_callback_g3mipt','g3mipt','Step 50',       50),
    (gid,'event_callback_v197np','v197np','Step 100',     100),
    (gid,'event_callback_vbwc0z','vbwc0z','Step 250',     250),
    (gid,'event_callback_j7pzey','j7pzey','Step 500',     500),
    (gid,'event_callback_47euyf','47euyf','Step 1000',   1000),
    (gid,'event_callback_jom3es','jom3es','Make a purchase',0),
    (gid,'event_callback_2i73t2','2i73t2','Purchase',        0);
END $$;

-- 2248 Puzzle
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_adj WHERE name='puzzle2248';
  INSERT INTO events_adj(game_id,event_name,event_token,display_name,level_value) VALUES
    (gid,'event_callback_lumf2i', 'lumf2i','Level 10',    10),
    (gid,'event_callback_p08k2f', 'p08k2f','Level 25',    25),
    (gid,'event_callback_cciiv6', 'cciiv6','Level 50',    50),
    (gid,'event_callback_yysyts', 'yysyts','Level 100',  100),
    (gid,'event_callback_dhwefa', 'dhwefa','Level 250',  250),
    (gid,'event_callback_hn8yew', 'hn8yew','Level 500',  500),
    (gid,'event_callback_igqmwt', 'igqmwt','Level 1000',1000),
    (gid,'event_callback_236tr52','236tr52','Session',      0);
END $$;

-- Alice in Blastland
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_adj WHERE name='alice_blastland';
  INSERT INTO events_adj(game_id,event_name,event_token,display_name,level_value) VALUES
    (gid,'event_callback_uefzz6','uefzz6','Reach Level 5',   5),
    (gid,'event_callback_15h2c4','15h2c4','Level 15',        15),
    (gid,'event_callback_x2o8is','x2o8is','First deposit',    0),
    (gid,'event_callback_dndphq','dndphq','Reach Level 30',  30),
    (gid,'event_callback_5oolhi','5oolhi','Reach Level 50',  50),
    (gid,'event_callback_l5p54c','l5p54c','Reach Level 100',100),
    (gid,'event_callback_yhj1lm','yhj1lm','Level 200',      200),
    (gid,'event_callback_i4juxt','i4juxt','Level 300',      300),
    (gid,'event_callback_oftnes','oftnes','Level 500',      500),
    (gid,'event_callback_z8ovou','z8ovou','Level 750',      750),
    (gid,'event_callback_qww7m6','qww7m6','Level 1000',    1000),
    (gid,'event_callback_25764', '25764', 'Session',          0);
END $$;

-- Army Tycoon
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_adj WHERE name='army_tycoon';
  INSERT INTO events_adj(game_id,event_name,event_token,display_name,level_value) VALUES
    (gid,'event_callback_ucfrab','ucfrab','Unlock Artillery Course',     1),
    (gid,'event_callback_kcii8f','kcii8f','Unlock Tank Course',          2),
    (gid,'event_callback_1tgiij','1tgiij','Unlock Indoor Shooting Range',3),
    (gid,'event_callback_x2b508','x2b508','Unlock Helicopter Course',    4),
    (gid,'event_callback_afpgpn','afpgpn','Event',                       5),
    (gid,'event_callback_24260', '24260', 'Session',                     0);
END $$;

-- Battle Night
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_adj WHERE name='battle_night';
  INSERT INTO events_adj(game_id,event_name,event_token,display_name,level_value) VALUES
    (gid,'event_callback_wdu1px','wdu1px','Collect 2 Purple Heroes',  2),
    (gid,'event_callback_at7h8t','at7h8t','Purchase Month Card',      0),
    (gid,'event_callback_f6z6gr','f6z6gr','Complete Chapter 6',       6),
    (gid,'event_callback_8no4ma','8no4ma','Buy Login Premium Pass',   0),
    (gid,'event_callback_jb6urh','jb6urh','Collect 1 Orange Hero',    1),
    (gid,'event_callback_lltjkz','lltjkz','2 Orange Hero',            2),
    (gid,'event_callback_9dy8xg','9dy8xg','4 Orange Hero',            4),
    (gid,'event_callback_z8vm09','z8vm09','6 Orange Hero',            6),
    (gid,'event_callback_98bp74','98bp74','9 Orange Hero',            9),
    (gid,'event_callback_9aqu0l','9aqu0l','Reach VIP Level 4',        4),
    (gid,'event_callback_36w4u0','36w4u0','12 Orange Hero',          12),
    (gid,'event_callback_xjcc3q','xjcc3q','15 Orange Hero',          15),
    (gid,'event_callback_4g2o7u','4g2o7u','1 Red Hero',               1);
END $$;

-- Berry Factory Tycoon
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_adj WHERE name='berry_factory';
  INSERT INTO events_adj(game_id,event_name,event_token,display_name,level_value) VALUES
    (gid,'event_callback_vex04j','vex04j','Reach Dessert Factory',      1),
    (gid,'event_callback_f28p6w','f28p6w','Reach Candy Combine',        2),
    (gid,'event_callback_rsrv4q','rsrv4q','Reach Jelly Concern',        3),
    (gid,'event_callback_rktc9a','rktc9a','Upgrade Glazer to Maximum',  4),
    (gid,'event_callback_32t74', '32t74', 'Session',                    0);
END $$;

-- Big Card Solitaire
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_adj WHERE name='big_card_solitaire';
  INSERT INTO events_adj(game_id,event_name,event_token,display_name,level_value) VALUES
    (gid,'event_callback_y0oh58','y0oh58','First Time Deposit',     0),
    (gid,'event_callback_58fm8f','58fm8f','Reach Level 15',        15),
    (gid,'event_callback_iecaaf','iecaaf','Level 20',              20),
    (gid,'event_callback_i31lvg','i31lvg','Level 30',              30),
    (gid,'event_callback_vjrg9q','vjrg9q','Collect 3K Coins',   3000),
    (gid,'event_callback_1fiiml','1fiiml','Collect 5K Coins',   5000),
    (gid,'event_callback_rbxsf1','rbxsf1','Collect 7K Coins',   7000),
    (gid,'event_callback_i4avja','i4avja','10K Coins',          10000),
    (gid,'event_callback_j2y6j9','j2y6j9','20K Coins',          20000),
    (gid,'event_callback_r5um2u','r5um2u','50K Coins',          50000),
    (gid,'event_callback_bbyp36','bbyp36','100K Coins',        100000),
    (gid,'event_callback_b8gfs7','b8gfs7','200K Coins',        200000),
    (gid,'event_callback_rb2zo3','rb2zo3','400K Coins',        400000);
END $$;

-- Bingo Aloha
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_adj WHERE name='bingo_aloha';
  INSERT INTO events_adj(game_id,event_name,event_token,display_name,level_value) VALUES
    (gid,'event_callback_tr4vq2','tr4vq2','Reach Level 20',              20),
    (gid,'event_callback_f82iiq','f82iiq','Level 30',                    30),
    (gid,'event_callback_ifxzih','ifxzih','Level 40',                    40),
    (gid,'event_callback_3yza9s','3yza9s','Level 50',                    50),
    (gid,'event_callback_pk6qyf','pk6qyf','Level 60 within 3 days',      60),
    (gid,'event_callback_w5tltt','w5tltt','Level 80',                    80),
    (gid,'event_callback_189lri','189lri','Level 120',                  120),
    (gid,'event_callback_3g5fjn','3g5fjn','Level 150',                  150),
    (gid,'event_callback_2vj74s','2vj74s','Level 200 within 6 days',    200),
    (gid,'event_callback_ccm57s','ccm57s','Level 300',                  300),
    (gid,'event_callback_pxvvbe','pxvvbe','Level 400',                  400),
    (gid,'event_callback_uqst83','uqst83','Level 500',                  500),
    (gid,'event_callback_3wfbqv','3wfbqv','Purchase $19.9',               0),
    (gid,'event_callback_ckugaz','ckugaz','Purchase $9.99',               0),
    (gid,'event_callback_uvz4f0','uvz4f0','Purchase $4.99',               0);
END $$;

-- Bingo Showdown
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_adj WHERE name='bingo_showdown';
  INSERT INTO events_adj(game_id,event_name,event_token,display_name,level_value) VALUES
    (gid,'event_callback_w10qxm','w10qxm','First Bingo',        1),
    (gid,'event_callback_3jdb4n','3jdb4n','Reach Level 2',      2),
    (gid,'event_callback_njnr15','njnr15','Level 3',            3),
    (gid,'event_callback_2sv8qt','2sv8qt','Level 5',            5),
    (gid,'event_callback_14h0b2','14h0b2','Level 10',          10),
    (gid,'event_callback_livykp','livykp','Level 15',          15),
    (gid,'event_callback_95ye13','95ye13','Level 20',          20),
    (gid,'event_callback_fjp3vm','fjp3vm','Level 25',          25),
    (gid,'event_callback_upmo7s','upmo7s','Level 50',          50),
    (gid,'event_callback_jkpze3','jkpze3','First Purchase',     0);
END $$;

-- Blast Friends
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_adj WHERE name='blast_friends';
  INSERT INTO events_adj(game_id,event_name,event_token,display_name,level_value) VALUES
    (gid,'event_callback_v5zsay','v5zsay','Reach Level 20',   20),
    (gid,'event_callback_qco1yc','qco1yc','Level 50',         50),
    (gid,'event_callback_nmbpbj','nmbpbj','Level 100',       100),
    (gid,'event_callback_7tcb9y','7tcb9y','Level 250',       250),
    (gid,'event_callback_a0tksk','a0tksk','Level 500',       500),
    (gid,'event_callback_r9ojpu','r9ojpu','Level 1000',     1000),
    (gid,'event_callback_8q1rrv','8q1rrv','Level 2000',     2000);
END $$;

-- Block Blitz
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_adj WHERE name='block_blitz';
  INSERT INTO events_adj(game_id,event_name,event_token,display_name,level_value) VALUES
    (gid,'event_callback_z9gmw7', 'z9gmw7', 'Win Journey Level 5',  5),
    (gid,'event_callback_erj7x3', 'erj7x3', 'Level 10',            10),
    (gid,'event_callback_1v5jpk', '1v5jpk', 'Level 20',            20),
    (gid,'event_callback_1puzhk', '1puzhk', 'Level 30',            30),
    (gid,'event_callback_fxhwo0', 'fxhwo0', 'Level 40',            40),
    (gid,'event_callback_bqkl2c', 'bqkl2c', 'Level 50',            50),
    (gid,'event_callback_tum80y', 'tum80y', 'Level 70',            70),
    (gid,'event_callback_nm5hzf', 'nm5hzf', 'Level 100',          100),
    (gid,'event_callback_ulzxtz', 'ulzxtz', 'Level 150',          150),
    (gid,'event_callback_q7kns1', 'q7kns1', 'Level 300',          300),
    (gid,'event_callback_uf24fv', 'uf24fv', 'Level 500',          500),
    (gid,'event_callback_vjp76b', 'vjp76b', 'Level 700',          700),
    (gid,'event_callback_nxjpvy', 'nxjpvy', 'Level 1000',        1000),
    (gid,'event_callback_1020304','1020304','First Time Purchase',   0);
END $$;

-- Block Joy Puzzle
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_adj WHERE name='block_joy';
  INSERT INTO events_adj(game_id,event_name,event_token,display_name,level_value) VALUES
    (gid,'event_callback_dvo8mu','dvo8mu','Level 5',     5),
    (gid,'event_callback_r45ld3','r45ld3','Level 10',   10),
    (gid,'event_callback_61mki6','61mki6','Level 20',   20),
    (gid,'event_callback_15q1fg','15q1fg','Level 30',   30),
    (gid,'event_callback_1ziiag','1ziiag','Level 50',   50),
    (gid,'event_callback_yh508k','yh508k','Level 70',   70),
    (gid,'event_callback_3gxgyp','3gxgyp','Level 100', 100),
    (gid,'event_callback_vev8ur','vev8ur','Level 150', 150),
    (gid,'event_callback_nazx5v','nazx5v','Level 300', 300),
    (gid,'event_callback_q98rl6','q98rl6','Level 500', 500),
    (gid,'event_callback_v1htdn','v1htdn','Level 700', 700),
    (gid,'event_callback_soa9vy','soa9vy','Level 1000',1000),
    (gid,'event_callback_c8ck9d','c8ck9d','First Purchase',0);
END $$;

-- Gems Adventure
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_adj WHERE name='gems_adventure';
  INSERT INTO events_adj(game_id,event_name,event_token,display_name,level_value) VALUES
    (gid,'event_callback_dwowyx','dwowyx','Score 3K',      3000),
    (gid,'event_callback_h2e11l','h2e11l','Score 5K',      5000),
    (gid,'event_callback_25ud1c','25ud1c','Score 10K',    10000),
    (gid,'event_callback_3vdhft','3vdhft','Score 25K',    25000),
    (gid,'event_callback_amhlay','amhlay','Score 50K',    50000),
    (gid,'event_callback_mkuzzm','mkuzzm','Score 100K',  100000),
    (gid,'event_callback_nyi04s','nyi04s','Score 250K',  250000),
    (gid,'event_callback_1v45em','1v45em','Score 500K',  500000),
    (gid,'event_callback_q3tfto','q3tfto','Score 750K',  750000),
    (gid,'event_callback_o9d9hb','o9d9hb','Score 1M',   1000000);
END $$;

-- Bravo Classic Slots
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_adj WHERE name='bravo_slots';
  INSERT INTO events_adj(game_id,event_name,event_token,display_name,level_value) VALUES
    (gid,'event_callback_pxnk4e','pxnk4e','Reach Level 40',       40),
    (gid,'event_callback_k6p17i','k6p17i','Reach Level 100',     100),
    (gid,'event_callback_fw0837','fw0837','Purchase Mission Pass',  0),
    (gid,'event_callback_i1l8xp','i1l8xp','Reach Level 200',     200),
    (gid,'event_callback_nlql3m','nlql3m','Reach Level 400',     400),
    (gid,'event_callback_1pvoa2','1pvoa2','Accum Purchase $9.99',  0),
    (gid,'event_callback_96j1vw','96j1vw','Reach Level 800',     800),
    (gid,'event_callback_jpw7pe','jpw7pe','Level 2000',          2000),
    (gid,'event_callback_y85bjt','y85bjt','Level 4000',          4000);
END $$;

-- Cash Storm
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_adj WHERE name='cash_storm';
  INSERT INTO events_adj(game_id,event_name,event_token,display_name,level_value) VALUES
    (gid,'event_callback_ht80ad','ht80ad','Complete Level 15',  15),
    (gid,'event_callback_ll59t0','ll59t0','Purchase $9.99',      0),
    (gid,'event_callback_47akr5','47akr5','Level 30',           30),
    (gid,'event_callback_yjd7i0','yjd7i0','Level 40',           40),
    (gid,'event_callback_fmwgmq','fmwgmq','Level 60',           60),
    (gid,'event_callback_6nulf0','6nulf0','Purchase $19.9',      0),
    (gid,'event_callback_6ppgib','6ppgib','Level 80',           80),
    (gid,'event_callback_qyasgc','qyasgc','Level 100',         100);
END $$;

-- Climb the Mountain
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_adj WHERE name='climb_mountain';
  INSERT INTO events_adj(game_id,event_name,event_token,display_name,level_value) VALUES
    (gid,'event_callback_xt4epl','xt4epl','Complete Level 25', 25),
    (gid,'event_callback_n2qh1u','n2qh1u','Level 100',        100),
    (gid,'event_callback_bssey9','bssey9','Level 300',        300);
END $$;

-- Clock Maker
DO $$ DECLARE gid INT; BEGIN
  SELECT id INTO gid FROM games_adj WHERE name='clock_maker';
  INSERT INTO events_adj(game_id,event_name,event_token,display_name,level_value) VALUES
    (gid,'event_callback_uu8lcy','uu8lcy','Unlock Stables',          1),
    (gid,'event_callback_64yi1x','64yi1x','Unlock the Mill',         2),
    (gid,'event_callback_gwqs4i','gwqs4i','Unlock Old Sam''s House',  3),
    (gid,'event_callback_uqry54','uqry54','Unlock Harrison''s Mansion',4),
    (gid,'event_callback_1nwuqr','1nwuqr','Unlock Fire Station',     5),
    (gid,'event_callback_as93wo','as93wo','Unlock Antique Shop',     6),
    (gid,'event_callback_86t122','86t122','Unlock Theatre',          7),
    (gid,'event_callback_t912za','t912za','Unlock School',           8),
    (gid,'event_callback_senibm','senibm','Unlock Fountain',         9),
    (gid,'event_callback_g8g4p2','g8g4p2','Unlock Clock Tower',     10),
    (gid,'event_callback_bev80p','bev80p','Purchase',                0);
END $$;

-- =====================================================
-- 11. باقات الاشتراك الافتراضية
-- =====================================================
INSERT INTO subscription_plans (name, duration_days, price, daily_limit, is_active) VALUES
('باقة يومية',   1,  2.00, 10, TRUE),
('باقة أسبوعية', 7,  5.00, 15, TRUE),
('باقة شهرية',  30, 15.00, 20, TRUE);

-- =====================================================
-- 12. إعدادات طرق الدفع الافتراضية
-- =====================================================
INSERT INTO payment_settings (method, display_name, address, instructions, is_active) VALUES
('usdt',          '💎 USDT (TRC20)',   '', 'أرسل المبلغ إلى العنوان أعلاه، ثم أدخل رقم العملية.', TRUE),
('sham_cash',     '💰 شام كاش',       '', 'أرسل المبلغ إلى الرقم أعلاه، ثم أرسل صورة إثبات الدفع.', TRUE),
('syriatel_cash', '💰 سرياتيل كاش',   '', 'أرسل المبلغ إلى الرقم أعلاه، ثم أرسل صورة إثبات الدفع.', TRUE);

-- =====================================================
-- 13. تحقق من النتيجة النهائية
-- =====================================================
SELECT '✅ الجداول' AS check, COUNT(*) AS count FROM information_schema.tables
  WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
UNION ALL
SELECT '🎮 AF Games',       COUNT(*) FROM games_af
UNION ALL
SELECT '📋 AF Events',      COUNT(*) FROM events_af
UNION ALL
SELECT '🎯 Singular Games', COUNT(*) FROM games_singular
UNION ALL
SELECT '📋 Singular Events',COUNT(*) FROM events_singular
UNION ALL
SELECT '🎰 Adj Games',      COUNT(*) FROM games_adj
UNION ALL
SELECT '📋 Adj Events',     COUNT(*) FROM events_adj
UNION ALL
SELECT '👤 Users',          COUNT(*) FROM users
UNION ALL
SELECT '✅ Allowed Users',  COUNT(*) FROM allowed_users
UNION ALL
SELECT '📦 Plans',          COUNT(*) FROM subscription_plans
UNION ALL
SELECT '💳 Payment Methods',COUNT(*) FROM payment_settings;
