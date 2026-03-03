// ============================================================
// PriVault – File Routes
// ============================================================

import { Router, Response } from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import crypto from 'crypto';
import { pool } from '../config/db';
import { authMiddleware } from '../middleware/auth';
import { logAudit } from '../helpers/auditLogger';
import { AuthRequest } from '../types';

const router = Router();

const storagePath = process.env.STORAGE_PATH || path.join(__dirname, '../../uploads');
if (!fs.existsSync(storagePath)) { fs.mkdirSync(storagePath, { recursive: true }); }

const upload = multer({
    storage: multer.diskStorage({
        destination: (req: AuthRequest, _file, cb) => {
            const userDir = path.join(storagePath, req.user!.id);
            if (!fs.existsSync(userDir)) fs.mkdirSync(userDir, { recursive: true });
            cb(null, userDir);
        },
        filename: (_req, _file, cb) => {
            const uniqueName = `${Date.now()}_${crypto.randomBytes(8).toString('hex')}`;
            cb(null, uniqueName);
        },
    }),
    limits: { fileSize: 500 * 1024 * 1024 },
});

// --- List files (BR-12) ---
router.get('/', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { folder_id, is_vault } = req.query;
        let query = `SELECT * FROM files_metadata WHERE user_id = $1 AND is_deleted = FALSE`;
        const params: (string | boolean)[] = [req.user!.id];

        if (folder_id) {
            query += ` AND folder_id = $2`;
            params.push(folder_id as string);
        } else {
            query += ` AND folder_id IS NULL`;
        }

        if (is_vault === 'true') {
            query += ` AND is_vault_file = TRUE`;
        } else {
            query += ` AND is_vault_file = FALSE`;
        }

        query += ` ORDER BY created_at DESC`;
        const result = await pool.query(query, params);
        res.json(result.rows);
    } catch (err) {
        console.error('List files error:', err);
        res.status(500).json({ error: 'Failed to list files' });
    }
});

// --- Upload file (BR-04, BR-05, BR-06, BR-10) ---
router.post('/upload', authMiddleware, upload.single('file'), async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const file = req.file;
        if (!file) { res.status(400).json({ error: 'No file provided' }); return; }

        const { folder_id, encrypted_name, file_key_encrypted, original_size, is_vault_file, company_id, team_id } = req.body;
        const sizeBytes = parseInt(original_size || file.size, 10);

        const userResult = await pool.query(
            'SELECT storage_used_bytes, storage_max_bytes FROM users WHERE id = $1',
            [req.user!.id]
        );
        const user = userResult.rows[0];

        if (user.storage_used_bytes + sizeBytes > user.storage_max_bytes) {
            fs.unlinkSync(file.path);
            res.status(413).json({ error: 'Storage quota exceeded. Delete files or upgrade.' }); return;
        }

        if (company_id) {
            const compResult = await pool.query(
                'SELECT storage_used_bytes, storage_max_bytes FROM companies WHERE id = $1',
                [company_id]
            );
            if (compResult.rows.length > 0) {
                const comp = compResult.rows[0];
                if (comp.storage_used_bytes + sizeBytes > comp.storage_max_bytes) {
                    fs.unlinkSync(file.path);
                    res.status(413).json({ error: 'Company storage quota exceeded.' }); return;
                }
            }
        }

        const fileStoragePath = `${req.user!.id}/${file.filename}`;

        const result = await pool.query(
            `INSERT INTO files_metadata (user_id, company_id, team_id, folder_id, name, encrypted_name, size_bytes, storage_path, file_key_encrypted, is_vault_file)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING *`,
            [req.user!.id, company_id || null, team_id || null, folder_id || null, fileStoragePath, encrypted_name || '', sizeBytes, fileStoragePath, file_key_encrypted || null, is_vault_file === 'true']
        );

        await pool.query('UPDATE users SET storage_used_bytes = storage_used_bytes + $1 WHERE id = $2', [sizeBytes, req.user!.id]);

        if (company_id) {
            await pool.query('UPDATE companies SET storage_used_bytes = storage_used_bytes + $1 WHERE id = $2', [sizeBytes, company_id]);
        }

        await logAudit({ userId: req.user!.id, companyId: company_id, action: 'file.upload', resourceType: 'file', resourceId: result.rows[0].id, req });
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error('Upload error:', err);
        res.status(500).json({ error: 'Upload failed' });
    }
});

// --- Download file (BR-12, BR-16) ---
router.get('/:id/download', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const fileResult = await pool.query('SELECT * FROM files_metadata WHERE id = $1', [req.params.id]);
        if (fileResult.rows.length === 0) { res.status(404).json({ error: 'File not found' }); return; }

        const file = fileResult.rows[0];
        const hasAccess = await checkFileAccess(req.user!.id, file);
        if (!hasAccess) { res.status(403).json({ error: 'Access denied' }); return; }

        const filePath = path.join(process.env.STORAGE_PATH || path.join(__dirname, '../../uploads'), file.storage_path);
        if (!fs.existsSync(filePath)) { res.status(404).json({ error: 'File not found on disk' }); return; }

        await logAudit({ userId: req.user!.id, companyId: file.company_id, action: 'file.download', resourceType: 'file', resourceId: file.id, req });
        res.download(filePath, file.name);
    } catch (err) {
        console.error('Download error:', err);
        res.status(500).json({ error: 'Download failed' });
    }
});

// --- Soft delete (BR-26) ---
router.delete('/:id', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const fileResult = await pool.query(
            'SELECT * FROM files_metadata WHERE id = $1 AND user_id = $2',
            [req.params.id, req.user!.id]
        );
        if (fileResult.rows.length === 0) { res.status(404).json({ error: 'File not found' }); return; }

        const file = fileResult.rows[0];
        await pool.query('UPDATE files_metadata SET is_deleted = TRUE, deleted_at = NOW() WHERE id = $1', [req.params.id]);
        await pool.query('UPDATE users SET storage_used_bytes = GREATEST(storage_used_bytes - $1, 0) WHERE id = $2', [file.size_bytes, req.user!.id]);

        if (file.company_id) {
            await pool.query('UPDATE companies SET storage_used_bytes = GREATEST(storage_used_bytes - $1, 0) WHERE id = $2', [file.size_bytes, file.company_id]);
        }

        await logAudit({ userId: req.user!.id, action: 'file.delete', resourceType: 'file', resourceId: file.id, req });
        res.json({ success: true });
    } catch (err) {
        console.error('Delete error:', err);
        res.status(500).json({ error: 'Delete failed' });
    }
});

// --- Restore from trash ---
router.put('/:id/restore', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const fileResult = await pool.query(
            'SELECT * FROM files_metadata WHERE id = $1 AND user_id = $2 AND is_deleted = TRUE',
            [req.params.id, req.user!.id]
        );
        if (fileResult.rows.length === 0) { res.status(404).json({ error: 'File not found in trash' }); return; }

        const file = fileResult.rows[0];
        const userResult = await pool.query('SELECT storage_used_bytes, storage_max_bytes FROM users WHERE id = $1', [req.user!.id]);
        const user = userResult.rows[0];
        if (user.storage_used_bytes + file.size_bytes > user.storage_max_bytes) {
            res.status(413).json({ error: 'Not enough storage to restore this file' }); return;
        }

        await pool.query('UPDATE files_metadata SET is_deleted = FALSE, deleted_at = NULL WHERE id = $1', [req.params.id]);
        await pool.query('UPDATE users SET storage_used_bytes = storage_used_bytes + $1 WHERE id = $2', [file.size_bytes, req.user!.id]);
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: 'Restore failed' });
    }
});

// --- Permanent delete (BR-27) ---
router.delete('/:id/permanent', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const fileResult = await pool.query(
            'SELECT * FROM files_metadata WHERE id = $1 AND user_id = $2',
            [req.params.id, req.user!.id]
        );
        if (fileResult.rows.length === 0) { res.status(404).json({ error: 'File not found' }); return; }

        const file = fileResult.rows[0];
        const filePath = path.join(process.env.STORAGE_PATH || path.join(__dirname, '../../uploads'), file.storage_path);
        if (fs.existsSync(filePath)) fs.unlinkSync(filePath);

        const versions = await pool.query('SELECT storage_path FROM file_versions WHERE file_id = $1', [file.id]);
        for (const v of versions.rows) {
            const vPath = path.join(process.env.STORAGE_PATH || path.join(__dirname, '../../uploads'), v.storage_path);
            if (fs.existsSync(vPath)) fs.unlinkSync(vPath);
        }

        await pool.query('DELETE FROM file_versions WHERE file_id = $1', [file.id]);
        await pool.query('DELETE FROM file_comments WHERE file_id = $1', [file.id]);
        await pool.query('DELETE FROM shares WHERE file_id = $1', [file.id]);
        await pool.query('DELETE FROM files_metadata WHERE id = $1', [file.id]);

        await logAudit({ userId: req.user!.id, action: 'file.permanent_delete', resourceType: 'file', resourceId: file.id, req });
        res.json({ success: true });
    } catch (err) {
        console.error('Permanent delete error:', err);
        res.status(500).json({ error: 'Permanent delete failed' });
    }
});

// --- Get trash (BR-26) ---
router.get('/trash/list', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const result = await pool.query(
            `SELECT *, EXTRACT(DAY FROM (NOW() - deleted_at)) as days_in_trash
       FROM files_metadata WHERE user_id = $1 AND is_deleted = TRUE ORDER BY deleted_at DESC`,
            [req.user!.id]
        );
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: 'Failed to get trash' });
    }
});

// --- Toggle favorite ---
router.post('/:id/favorite', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        await pool.query(
            'UPDATE files_metadata SET is_favorite = NOT is_favorite WHERE id = $1 AND user_id = $2',
            [req.params.id, req.user!.id]
        );
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: 'Failed to toggle favorite' });
    }
});

// --- Helper: Check file access (BR-12) ---
export async function checkFileAccess(userId: string, file: Record<string, unknown>): Promise<boolean> {
    if (file.user_id === userId) return true;

    const shareAccess = await pool.query(
        `SELECT sr.id FROM share_recipients sr
     JOIN shares s ON s.id = sr.share_id
     WHERE sr.recipient_id = $1 AND s.file_id = $2 AND s.is_revoked = FALSE
       AND (s.expires_at IS NULL OR s.expires_at > NOW())`,
        [userId, file.id]
    );
    if (shareAccess.rows.length > 0) return true;

    const teamAccess = await pool.query(
        `SELECT s.id FROM shares s
     JOIN team_members tm ON tm.team_id = s.shared_with_team_id
     WHERE tm.user_id = $1 AND s.file_id = $2 AND s.is_revoked = FALSE
       AND (s.expires_at IS NULL OR s.expires_at > NOW())`,
        [userId, file.id]
    );
    if (teamAccess.rows.length > 0) return true;

    if (file.company_id) {
        const compAccess = await pool.query(
            'SELECT id FROM company_members WHERE company_id = $1 AND user_id = $2 AND is_active = TRUE',
            [file.company_id as string, userId]
        );
        if (compAccess.rows.length > 0) return true;
    }

    return false;
}

export default router;
