// ============================================================
// PriVault – File Comment Routes (BR-COM-01–03)
// ============================================================

import { Router, Response } from 'express';
import { pool } from '../config/db';
import { authMiddleware } from '../middleware/auth';
import { logAudit } from '../helpers/auditLogger';
import { AuthRequest } from '../types';

const router = Router();

// --- Get comments for a file (BR-COM-01) ---
router.get('/:fileId/comments', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const result = await pool.query(
            `SELECT fc.*, u.email, u.display_name FROM file_comments fc
       JOIN users u ON u.id = fc.user_id
       WHERE fc.file_id = $1 ORDER BY fc.created_at ASC`,
            [req.params.fileId]
        );
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: 'Failed to get comments' });
    }
});

// --- Add comment (BR-COM-01, BR-COM-02, BR-COM-03) ---
router.post('/:fileId/comments', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { content } = req.body as { content?: string };
        if (!content || typeof content !== 'string') {
            res.status(400).json({ error: 'Comment content required' }); return;
        }

        if (content.length > 750) {
            res.status(400).json({ error: 'Comment must be 750 characters or less' }); return;
        }

        const urlRegex = /https?:\/\/[^\s]+/gi;
        if (urlRegex.test(content)) {
            res.status(400).json({ error: 'External links are not allowed in comments' }); return;
        }

        const result = await pool.query(
            `INSERT INTO file_comments (file_id, user_id, content)
       VALUES ($1, $2, $3) RETURNING *`,
            [req.params.fileId, req.user!.id, content.trim()]
        );

        await logAudit({ userId: req.user!.id, action: 'comment.create', resourceType: 'file', resourceId: req.params.fileId, req });
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: 'Failed to add comment' });
    }
});

// --- Delete comment ---
router.delete('/comments/:id', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const result = await pool.query(
            'DELETE FROM file_comments WHERE id = $1 AND user_id = $2 RETURNING id',
            [req.params.id, req.user!.id]
        );
        if (result.rows.length === 0) { res.status(404).json({ error: 'Comment not found' }); return; }
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: 'Failed to delete comment' });
    }
});

export default router;
