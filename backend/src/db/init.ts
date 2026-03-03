// ============================================================
// PriVault – Database Initialization Script
// ============================================================
// Usage: ts-node src/db/init.ts

import dotenv from 'dotenv';
dotenv.config();

import fs from 'fs';
import path from 'path';
import { pool } from '../config/db';

async function initDatabase(): Promise<void> {
    try {
        console.log('🔄 Initializing database...');

        const schemaPath = path.join(__dirname, 'schema.sql');
        const schema = fs.readFileSync(schemaPath, 'utf8');

        await pool.query(schema);

        console.log('✅ Database initialized successfully');
        process.exit(0);
    } catch (err) {
        console.error('❌ Database initialization failed:', err);
        process.exit(1);
    }
}

initDatabase();
