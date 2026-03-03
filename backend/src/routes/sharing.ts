// ============================================================
// PriVault – Sharing Routes (BR-13, BR-14, BR-15)
// ============================================================

import { Router, Response } from 'express';
import { pool } from '../config/db';
import { authMiddleware } from '../middleware/auth';
import { logAudit } from '../helpers/auditLogger';
import { AuthRequest } from '../types';

const router = Router();

// --- Create link share (BR-13) ---
router.post('/link', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { file_id, folder_id, encrypted_key, permission, expires_at, max_downloads } = req.body;
        if (!file_id && !folder_id) { res.status(400).json({ error: 'file_id or folder_id required' }); return; }

        if (file_id) {
            const f = await pool.query('SELECT id, is_vault_file FROM files_metadata WHERE id = $1 AND user_id = $2', [file_id, req.user!.id]);
            if (f.rows.length === 0) { res.status(404).json({ error: 'File not found' }); return; }
            if (f.rows[0].is_vault_file) { res.status(403).json({ error: 'Vault files cannot be shared externally' }); return; }
        }

        const result = await pool.query(
            `INSERT INTO shares (owner_id, file_id, folder_id, type, encrypted_key, permission, expires_at, max_downloads)
       VALUES ($1, $2, $3, 'link', $4, $5, $6, $7) RETURNING *`,
            [req.user!.id, file_id || null, folder_id || null, encrypted_key, permission || 'view', expires_at || null, max_downloads || 0]
        );

        await logAudit({ userId: req.user!.id, action: 'share.create_link', resourceType: 'file', resourceId: file_id, req });
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error('Create link error:', err);
        res.status(500).json({ error: 'Failed to create share link' });
    }
});

// --- Share with email (BR-13) ---
router.post('/email', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { file_id, recipient_email, encrypted_key, permission, expires_at, recipient_encrypted_key } = req.body;
        if (!file_id || !recipient_email) { res.status(400).json({ error: 'file_id and recipient_email required' }); return; }

        const fileCheck = await pool.query('SELECT is_vault_file FROM files_metadata WHERE id = $1 AND user_id = $2', [file_id, req.user!.id]);
        if (fileCheck.rows.length === 0) { res.status(404).json({ error: 'File not found' }); return; }
        if (fileCheck.rows[0].is_vault_file) { res.status(403).json({ error: 'Vault files cannot be shared' }); return; }

        const recipientResult = await pool.query('SELECT id, public_key FROM users WHERE email = $1', [recipient_email]);
        if (recipientResult.rows.length === 0) { res.status(404).json({ error: 'Recipient not found' }); return; }

        const recipient = recipientResult.rows[0];

        const shareResult = await pool.query(
            `INSERT INTO shares (owner_id, file_id, type, encrypted_key, permission, expires_at)
       VALUES ($1, $2, 'user', $3, $4, $5) RETURNING *`,
            [req.user!.id, file_id, encrypted_key || null, permission || 'view', expires_at || null]
        );

        await pool.query(
            `INSERT INTO share_recipients (share_id, recipient_id, encrypted_key)
       VALUES ($1, $2, $3)`,
            [shareResult.rows[0].id, recipient.id, recipient_encrypted_key || encrypted_key || '']
        );

        await logAudit({ userId: req.user!.id, action: 'share.create_email', resourceType: 'file', resourceId: file_id, req, metadata: { recipient_email } });
        res.status(201).json(shareResult.rows[0]);
    } catch (err) {
        console.error('Share email error:', err);
        res.status(500).json({ error: 'Failed to share with user' });
    }
});

// --- Share with team (BR-13) ---
router.post('/team', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { file_id, team_id, encrypted_key, permission, expires_at } = req.body;
        if (!file_id || !team_id) { res.status(400).json({ error: 'file_id and team_id required' }); return; }

        const result = await pool.query(
            `INSERT INTO shares (owner_id, file_id, type, encrypted_key, permission, expires_at, shared_with_team_id)
       VALUES ($1, $2, 'team', $3, $4, $5, $6) RETURNING *`,
            [req.user!.id, file_id, encrypted_key, permission || 'view', expires_at || null, team_id]
        );

        await logAudit({ userId: req.user!.id, action: 'share.create_team', resourceType: 'file', resourceId: file_id, req });
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: 'Failed to share with team' });
    }
});

// --- Get my shares ---
router.get('/mine', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const result = await pool.query(
            `SELECT s.*, fm.encrypted_name, fm.size_bytes FROM shares s
       LEFT JOIN files_metadata fm ON fm.id = s.file_id
       WHERE s.owner_id = $1 ORDER BY s.created_at DESC`,
            [req.user!.id]
        );
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: 'Failed to list shares' });
    }
});

// --- Get shared with me ---
router.get('/with-me', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const result = await pool.query(
            `SELECT s.*, sr.encrypted_key as recipient_key, fm.encrypted_name, fm.size_bytes, fm.storage_path
       FROM share_recipients sr
       JOIN shares s ON s.id = sr.share_id
       LEFT JOIN files_metadata fm ON fm.id = s.file_id
       WHERE sr.recipient_id = $1 AND s.is_revoked = FALSE
         AND (s.expires_at IS NULL OR s.expires_at > NOW())
       ORDER BY s.created_at DESC`,
            [req.user!.id]
        );
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: 'Failed to list shared files' });
    }
});

// --- Revoke share (BR-15) ---
router.delete('/:id', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const result = await pool.query(
            'UPDATE shares SET is_revoked = TRUE WHERE id = $1 AND owner_id = $2 RETURNING *',
            [req.params.id, req.user!.id]
        );
        if (result.rows.length === 0) { res.status(404).json({ error: 'Share not found' }); return; }

        await logAudit({ userId: req.user!.id, action: 'share.revoke', resourceType: 'share', resourceId: req.params.id, req });
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: 'Failed to revoke share' });
    }
});

// --- Update share permissions (BR-14) ---
router.put('/:id/permissions', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { permission, expires_at } = req.body;
        const result = await pool.query(
            'UPDATE shares SET permission = COALESCE($1, permission), expires_at = COALESCE($2, expires_at) WHERE id = $3 AND owner_id = $4 RETURNING *',
            [permission, expires_at, req.params.id, req.user!.id]
        );
        if (result.rows.length === 0) { res.status(404).json({ error: 'Share not found' }); return; }

        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: 'Failed to update permissions' });
    }
});

export default router;
