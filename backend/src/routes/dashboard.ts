// ============================================================
// PriVault – Dashboard Routes (BR-25)
// ============================================================

import { Router, Response } from 'express';
import { pool } from '../config/db';
import { authMiddleware } from '../middleware/auth';
import { AuthRequest } from '../types';

const router = Router();

// --- Dashboard stats (BR-25) ---
router.get('/stats', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const storageResult = await pool.query(
            'SELECT storage_used_bytes, storage_max_bytes FROM users WHERE id = $1',
            [req.user!.id]
        );

        const filesResult = await pool.query(
            'SELECT COUNT(*) as total FROM files_metadata WHERE user_id = $1 AND is_deleted = FALSE',
            [req.user!.id]
        );

        const sharedResult = await pool.query(
            'SELECT COUNT(*) as total FROM shares WHERE owner_id = $1 AND is_revoked = FALSE',
            [req.user!.id]
        );

        const trashResult = await pool.query(
            'SELECT COUNT(*) as total FROM files_metadata WHERE user_id = $1 AND is_deleted = TRUE',
            [req.user!.id]
        );

        const topFiles = await pool.query(
            `SELECT fm.id, fm.encrypted_name, fm.size_bytes, COUNT(al.id) as access_count
       FROM audit_logs al
       JOIN files_metadata fm ON fm.id = al.resource_id::uuid
       WHERE al.user_id = $1 AND al.resource_type = 'file' AND al.action IN ('file.download', 'file.view')
         AND al.created_at > NOW() - INTERVAL '30 days'
       GROUP BY fm.id, fm.encrypted_name, fm.size_bytes
       ORDER BY access_count DESC LIMIT 10`,
            [req.user!.id]
        );

        res.json({
            storage: storageResult.rows[0] || { storage_used_bytes: 0, storage_max_bytes: 3221225472 },
            total_files: parseInt(filesResult.rows[0].total, 10),
            shared_files: parseInt(sharedResult.rows[0].total, 10),
            trash_files: parseInt(trashResult.rows[0].total, 10),
            top_files: topFiles.rows,
        });
    } catch (err) {
        console.error('Dashboard stats error:', err);
        res.status(500).json({ error: 'Failed to get stats' });
    }
});

// --- Weekly activity chart (BR-25) ---
router.get('/activity', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const result = await pool.query(
            `SELECT DATE(created_at) as day, action, COUNT(*) as count
       FROM audit_logs
       WHERE user_id = $1 AND created_at > NOW() - INTERVAL '7 days'
       GROUP BY DATE(created_at), action
       ORDER BY day ASC`,
            [req.user!.id]
        );
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: 'Failed to get activity' });
    }
});

export default router;
