use rusqlite::Connection;

pub fn open_db(path: &str) -> Connection {
    let conn = Connection::open(path).expect("Failed to open database");
    conn.execute_batch(
        "CREATE TABLE IF NOT EXISTS stats (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            tool_calls INTEGER NOT NULL DEFAULT 0,
            unique_agents INTEGER NOT NULL DEFAULT 0,
            agent_minutes REAL NOT NULL DEFAULT 0.0
        );
        INSERT OR IGNORE INTO stats (id) VALUES (1);",
    )
    .expect("Failed to initialize database");
    conn
}

pub fn load_stats(conn: &Connection) -> (u64, u64, f64) {
    conn.query_row(
        "SELECT tool_calls, unique_agents, agent_minutes FROM stats WHERE id = 1",
        [],
        |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?)),
    )
    .unwrap_or((0, 0, 0.0))
}

pub fn save_stats(conn: &Connection, tool_calls: u64, unique_agents: u64, agent_minutes: f64) {
    conn.execute(
        "INSERT OR REPLACE INTO stats (id, tool_calls, unique_agents, agent_minutes) VALUES (1, ?1, ?2, ?3)",
        rusqlite::params![tool_calls, unique_agents, agent_minutes],
    )
    .ok();
}
