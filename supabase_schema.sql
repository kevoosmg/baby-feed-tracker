-- 在 Supabase SQL Editor 中执行以下全部 SQL
-- 打开: https://supabase.com/dashboard/project/xfkixutmglsbxlimkbtn/sql/new

-- 1. 喂奶记录表
CREATE TABLE IF NOT EXISTS feed_records (
  id BIGSERIAL PRIMARY KEY,
  baby TEXT NOT NULL,
  time TIMESTAMPTZ NOT NULL,
  amount INTEGER NOT NULL,
  note TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 维生素记录表
CREATE TABLE IF NOT EXISTS vitamin_records (
  id BIGSERIAL PRIMARY KEY,
  type TEXT NOT NULL,
  date_key DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(type, date_key)
);

-- 3. 开启 RLS
ALTER TABLE feed_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE vitamin_records ENABLE ROW LEVEL SECURITY;

-- 4. 允许公开读写（家庭私用，URL不外泄即可）
CREATE POLICY "public_read" ON feed_records FOR SELECT USING (true);
CREATE POLICY "public_insert" ON feed_records FOR INSERT WITH CHECK (true);
CREATE POLICY "public_delete" ON feed_records FOR DELETE USING (true);

CREATE POLICY "public_read" ON vitamin_records FOR SELECT USING (true);
CREATE POLICY "public_insert" ON vitamin_records FOR INSERT WITH CHECK (true);
CREATE POLICY "public_update" ON vitamin_records FOR UPDATE USING (true);

-- 5. 启用实时同步
ALTER PUBLICATION supabase_realtime ADD TABLE feed_records;
ALTER PUBLICATION supabase_realtime ADD TABLE vitamin_records;
