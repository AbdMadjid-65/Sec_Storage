// ============================================================
// PriVault – Storage Routes (BR-04, BR-05, BR-06)
// ============================================================

import { Router, Response } from 'express';
import { pool } from '../config/db';
import { authMiddleware } from '../middleware/auth';
import { AuthRequest } from '../types';

const router = Router();

// --- Get storage usage ---
router.get('/usage', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const result = await pool.query(
            'SELECT storage_used_bytes, storage_max_bytes FROM users WHERE id = $1',
            [req.user!.id]
        );
        if (result.rows.length === 0) { res.status(404).json({ error: 'User not found' }); return; }

        const user = result.rows[0];
        res.json({
            used_bytes: parseInt(user.storage_used_bytes, 10),
            max_bytes: parseInt(user.storage_max_bytes, 10),
            used_percent: ((user.storage_used_bytes / user.storage_max_bytes) * 100).toFixed(1),
            remaining_bytes: user.storage_max_bytes - user.storage_used_bytes,
        });
    } catch (err) {
        res.status(500).json({ error: 'Failed to get storage usage' });
    }
});

// --- Get quota info including company ---
router.get('/quota', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const userResult = await pool.query(
            'SELECT storage_used_bytes, storage_max_bytes FROM users WHERE id = $1',
            [req.user!.id]
        );

        const companyResult = await pool.query(
            `SELECT c.id, c.name, c.storage_used_bytes, c.storage_max_bytes, cm.storage_quota_bytes
       FROM company_members cm JOIN companies c ON c.id = cm.company_id
       WHERE cm.user_id = $1 AND cm.is_active = TRUE`,
            [req.user!.id]
        );

        res.json({
            personal: userResult.rows[0],
            companies: companyResult.rows,
        });
    } catch (err) {
        res.status(500).json({ error: 'Failed to get quota' });
    }
});

export default router;
