// ============================================================
// PriVault – Profile Routes
// ============================================================

import { Router, Response } from 'express';
import { pool } from '../config/db';
import { authMiddleware } from '../middleware/auth';
import { AuthRequest } from '../types';

const router = Router();

// --- Get my profile ---
router.get('/me', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const result = await pool.query(
            'SELECT id, email, display_name, avatar_url, account_type, salt, public_key, storage_used_bytes, storage_max_bytes, is_2fa_enabled, created_at FROM users WHERE id = $1',
            [req.user!.id]
        );
        if (result.rows.length === 0) { res.status(404).json({ error: 'Profile not found' }); return; }

        const companies = await pool.query(
            `SELECT c.id, c.name, cm.role FROM company_members cm
       JOIN companies c ON c.id = cm.company_id
       WHERE cm.user_id = $1 AND cm.is_active = TRUE`,
            [req.user!.id]
        );

        res.json({ ...result.rows[0], companies: companies.rows });
    } catch (err) {
        res.status(500).json({ error: 'Failed to get profile' });
    }
});

// --- Update my profile ---
router.put('/me', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { display_name, avatar_url, public_key, salt } = req.body as {
            display_name?: string; avatar_url?: string; public_key?: string; salt?: string;
        };
        const result = await pool.query(
            `UPDATE users SET
         display_name = COALESCE($1, display_name),
         avatar_url = COALESCE($2, avatar_url),
         public_key = COALESCE($3, public_key),
         salt = COALESCE($4, salt)
       WHERE id = $5 RETURNING id, email, display_name, avatar_url, account_type, salt, public_key, storage_used_bytes, storage_max_bytes`,
            [display_name, avatar_url, public_key, salt, req.user!.id]
        );
        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: 'Failed to update profile' });
    }
});

export default router;
