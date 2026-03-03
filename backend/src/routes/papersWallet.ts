// ============================================================
// PriVault – Papers Wallet Routes (BR-22)
// ============================================================

import { Router, Response } from 'express';
import { pool } from '../config/db';
import { authMiddleware } from '../middleware/auth';
import { logAudit } from '../helpers/auditLogger';
import { AuthRequest } from '../types';

const router = Router();

const VALID_TYPES = ['id', 'student_card', 'employee_card', 'bank_card'];

// --- List wallet items ---
router.get('/', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const result = await pool.query(
            'SELECT * FROM papers_wallet_items WHERE user_id = $1 ORDER BY created_at DESC',
            [req.user!.id]
        );
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: 'Failed to get wallet items' });
    }
});

// --- Add item ---
router.post('/', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { type, encrypted_data } = req.body as { type?: string; encrypted_data?: string };
        if (!type || !encrypted_data) { res.status(400).json({ error: 'Type and encrypted_data required' }); return; }
        if (!VALID_TYPES.includes(type)) { res.status(400).json({ error: `Type must be one of: ${VALID_TYPES.join(', ')}` }); return; }

        const result = await pool.query(
            'INSERT INTO papers_wallet_items (user_id, type, encrypted_data) VALUES ($1, $2, $3) RETURNING *',
            [req.user!.id, type, encrypted_data]
        );

        await logAudit({ userId: req.user!.id, action: 'papers_wallet.add', resourceType: 'papers_wallet', resourceId: result.rows[0].id, req });
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: 'Failed to add wallet item' });
    }
});

// --- Update item ---
router.put('/:id', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { encrypted_data } = req.body as { encrypted_data?: string };
        if (!encrypted_data) { res.status(400).json({ error: 'encrypted_data required' }); return; }

        const result = await pool.query(
            'UPDATE papers_wallet_items SET encrypted_data = $1 WHERE id = $2 AND user_id = $3 RETURNING *',
            [encrypted_data, req.params.id, req.user!.id]
        );
        if (result.rows.length === 0) { res.status(404).json({ error: 'Item not found' }); return; }

        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: 'Failed to update wallet item' });
    }
});

// --- Delete item ---
router.delete('/:id', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const result = await pool.query(
            'DELETE FROM papers_wallet_items WHERE id = $1 AND user_id = $2 RETURNING id',
            [req.params.id, req.user!.id]
        );
        if (result.rows.length === 0) { res.status(404).json({ error: 'Item not found' }); return; }

        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: 'Failed to delete wallet item' });
    }
});

export default router;
