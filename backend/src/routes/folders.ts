// ============================================================
// PriVault – Folder Routes
// ============================================================

import { Router, Response } from 'express';
import { pool } from '../config/db';
import { authMiddleware } from '../middleware/auth';
import { logAudit } from '../helpers/auditLogger';
import { AuthRequest } from '../types';

const router = Router();

// --- List folders ---
router.get('/', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { parent_id } = req.query;
        let query: string;
        let params: string[];

        if (parent_id) {
            query = 'SELECT * FROM folders WHERE user_id = $1 AND parent_id = $2 ORDER BY name';
            params = [req.user!.id, parent_id as string];
        } else {
            query = 'SELECT * FROM folders WHERE user_id = $1 AND parent_id IS NULL ORDER BY name';
            params = [req.user!.id];
        }

        const result = await pool.query(query, params);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: 'Failed to list folders' });
    }
});

// --- Create folder ---
router.post('/', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { name, parent_id, company_id, team_id } = req.body as {
            name?: string; parent_id?: string; company_id?: string; team_id?: string;
        };
        if (!name) { res.status(400).json({ error: 'Folder name required' }); return; }

        const result = await pool.query(
            `INSERT INTO folders (user_id, company_id, team_id, parent_id, name)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
            [req.user!.id, company_id || null, team_id || null, parent_id || null, name]
        );

        await logAudit({ userId: req.user!.id, action: 'folder.create', resourceType: 'folder', resourceId: result.rows[0].id, req });
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: 'Failed to create folder' });
    }
});

// --- Rename folder ---
router.put('/:id', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { name } = req.body as { name?: string };
        if (!name) { res.status(400).json({ error: 'New name required' }); return; }

        const result = await pool.query(
            'UPDATE folders SET name = $1 WHERE id = $2 AND user_id = $3 RETURNING *',
            [name, req.params.id, req.user!.id]
        );
        if (result.rows.length === 0) { res.status(404).json({ error: 'Folder not found' }); return; }

        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: 'Failed to rename folder' });
    }
});

// --- Delete folder ---
router.delete('/:id', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        await pool.query(
            `UPDATE files_metadata SET is_deleted = TRUE, deleted_at = NOW()
       WHERE folder_id = $1 AND user_id = $2`,
            [req.params.id, req.user!.id]
        );

        await pool.query('DELETE FROM folders WHERE id = $1 AND user_id = $2', [req.params.id, req.user!.id]);
        await logAudit({ userId: req.user!.id, action: 'folder.delete', resourceType: 'folder', resourceId: req.params.id, req });

        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: 'Failed to delete folder' });
    }
});

export default router;
