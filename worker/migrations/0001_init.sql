-- T06 플랜두씨 다이어리 — 초기 스키마

CREATE TABLE plans (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  period_start TEXT NOT NULL,      -- YYYY-MM-DD
  period_end TEXT NOT NULL,        -- YYYY-MM-DD
  priority TEXT NOT NULL,          -- 'high' | 'medium' | 'low'
  success_criteria TEXT NOT NULL,
  estimated_hours REAL NOT NULL,
  source_reflection_id TEXT,       -- 이전 돌아보기의 고칠 점이 이 계획으로 넘어왔으면 그 id
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- 계획을 고칠 때마다, 고치기 전 값을 스냅샷으로 남긴다 (T06-C08)
CREATE TABLE plan_history (
  id TEXT PRIMARY KEY,
  plan_id TEXT NOT NULL REFERENCES plans(id),
  title TEXT NOT NULL,
  period_start TEXT NOT NULL,
  period_end TEXT NOT NULL,
  priority TEXT NOT NULL,
  success_criteria TEXT NOT NULL,
  estimated_hours REAL NOT NULL,
  snapshot_at TEXT NOT NULL         -- 이 스냅샷이 찍힌(=수정이 일어난) 시각
);

CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  plan_id TEXT NOT NULL REFERENCES plans(id),
  title TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'in_progress',  -- 'in_progress' | 'done'
  due_date TEXT,                    -- YYYY-MM-DD, nullable
  priority TEXT NOT NULL DEFAULT 'medium',
  tags TEXT NOT NULL DEFAULT '[]',  -- JSON 배열 문자열
  estimated_hours REAL NOT NULL DEFAULT 0,
  completed_at TEXT,
  deleted_at TEXT,                  -- soft delete, NULL이면 살아있음
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- 완료 전환을 append-only로 기록 (같은 순간의 중복 클릭은 UPDATE...WHERE로 막고, 진짜 재완료는 새 행)
CREATE TABLE completion_events (
  id TEXT PRIMARY KEY,
  task_id TEXT NOT NULL REFERENCES tasks(id),
  completed_at TEXT NOT NULL
);

-- 실행 기록: 계획(tasks)과 별개로 실제로 한 일을 남긴다 (T06-C23~C27)
CREATE TABLE execution_logs (
  id TEXT PRIMARY KEY,
  task_id TEXT NOT NULL REFERENCES tasks(id),
  started_at TEXT NOT NULL,
  ended_at TEXT NOT NULL,
  actual_minutes REAL NOT NULL,
  blocked_reason TEXT,
  created_at TEXT NOT NULL
);

-- 돌아보기에서 다음 계획으로 넘기는 고칠 점 한 줄 (T06-C33)
CREATE TABLE reflections (
  id TEXT PRIMARY KEY,
  plan_id TEXT NOT NULL REFERENCES plans(id),  -- 어떤 계획을 돌아보며 나온 메모인지
  note TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE INDEX idx_tasks_plan ON tasks(plan_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_execlogs_task ON execution_logs(task_id);
CREATE INDEX idx_planhistory_plan ON plan_history(plan_id);
