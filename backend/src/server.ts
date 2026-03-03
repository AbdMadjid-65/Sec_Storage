// ============================================================
// PriVault – Express Server Entry Point
// ============================================================

import dotenv from 'dotenv';
dotenv.config();

import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import path from 'path';
import fs from 'fs';

import { deviceInfoMiddleware } from './middleware/deviceInfo';

// Route imports
import authRoutes from './routes/auth';
import fileRoutes from './routes/files';
import folderRoutes from './routes/folders';
import sharingRoutes from './routes/sharing';
import companyRoutes from './routes/company';
import auditRoutes from './routes/audit';
import commentRoutes from './routes/comments';
import dashboardRoutes from './routes/dashboard';
import papersWalletRoutes from './routes/papersWallet';
import secureVaultRoutes from './routes/secureVault';
import profileRoutes from './routes/profiles';
import storageRoutes from './routes/storage';

import { pool } from './config/db';

const app = express();
const PORT = parseInt(process.env.PORT || '3000', 10);

// --- Global Middleware ---
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(deviceInfoMiddleware);

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 200,
    standardHeaders: true,
    legacyHeaders: false,
});
app.use('/api/', limiter);

const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 20,
    message: { error: 'Too many auth attempts. Please try again later.' },
});
app.use('/api/auth/', authLimiter);

// Ensure upload directory exists
const storagePath = process.env.STORAGE_PATH || path.join(__dirname, '../uploads');
if (!fs.existsSync(storagePath)) {
    fs.mkdirSync(storagePath, { recursive: true });
}

// --- API Routes ---
app.use('/api/auth', authRoutes);
app.use('/api/files', fileRoutes);
app.use('/api/folders', folderRoutes);
app.use('/api/shares', sharingRoutes);
app.use('/api/companies', companyRoutes);
app.use('/api/audit-logs', auditRoutes);
app.use('/api/files', commentRoutes);       // /api/files/:id/comments
app.use('/api', commentRoutes);             // /api/comments/:id (delete)
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/papers-wallet', papersWalletRoutes);
app.use('/api/secure-vault', secureVaultRoutes);
app.use('/api/profiles', profileRoutes);
app.use('/api/storage', storageRoutes);

// --- Health check ---
app.get('/api/health', (_req: Request, res: Response) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// --- Trash auto-purge scheduler (BR-26: 30 days) ---
async function purgeExpiredTrash(): Promise<void> {
    try {
        const expired = await pool.query(
            `SELECT id, storage_path, user_id, company_id, size_bytes FROM files_metadata
       WHERE is_deleted = TRUE AND deleted_at < NOW() - INTERVAL '30 days'`
        );

        for (const file of expired.rows) {
            const filePath = path.join(storagePath, file.storage_path);
            if (fs.existsSync(filePath)) fs.unlinkSync(filePath);

            const versions = await pool.query('SELECT storage_path FROM file_versions WHERE file_id = $1', [file.id]);
            for (const v of versions.rows) {
                const vPath = path.join(storagePath, v.storage_path);
                if (fs.existsSync(vPath)) fs.unlinkSync(vPath);
            }

            await pool.query('DELETE FROM file_versions WHERE file_id = $1', [file.id]);
            await pool.query('DELETE FROM file_comments WHERE file_id = $1', [file.id]);
            await pool.query('DELETE FROM shares WHERE file_id = $1', [file.id]);
            await pool.query('DELETE FROM files_metadata WHERE id = $1', [file.id]);
        }

        if (expired.rows.length > 0) {
            console.log(`🗑️  Purged ${expired.rows.length} expired trash files`);
        }
    } catch (err) {
        console.error('Trash purge error:', err);
    }
}

// Run purge every hour
setInterval(purgeExpiredTrash, 60 * 60 * 1000);

// --- Error handler ---
app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
    console.error('Unhandled error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

// --- Start ---
app.listen(PORT, () => {
    console.log(`🚀 PriVault API running on port ${PORT}`);
    console.log(`📂 Storage path: ${storagePath}`);
    purgeExpiredTrash();
});

export default app;
