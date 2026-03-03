// ============================================================
// PriVault – Company Routes (BR-18–20, BR-COMP-*)
// ============================================================

import { Router, Response } from 'express';
import { pool } from '../config/db';
import { authMiddleware } from '../middleware/auth';
import { logAudit } from '../helpers/auditLogger';
import { AuthRequest } from '../types';

const router = Router();

// --- Create company (BR-COMP-01) ---
router.post('/', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { name, official_email } = req.body as { name?: string; official_email?: string };
        if (!name || !official_email) { res.status(400).json({ error: 'Company name and official email required' }); return; }

        const result = await pool.query(
            `INSERT INTO companies (name, official_email, owner_id)
       VALUES ($1, $2, $3) RETURNING *`,
            [name, official_email, req.user!.id]
        );
        const company = result.rows[0];

        await pool.query(
            `INSERT INTO company_members (company_id, user_id, role)
       VALUES ($1, $2, 'owner')`,
            [company.id, req.user!.id]
        );

        await pool.query("UPDATE users SET account_type = 'company' WHERE id = $1", [req.user!.id]);
        await logAudit({ userId: req.user!.id, companyId: company.id, action: 'company.create', resourceType: 'company', resourceId: company.id, req });
        res.status(201).json(company);
    } catch (err) {
        console.error('Create company error:', err);
        res.status(500).json({ error: 'Failed to create company' });
    }
});

// --- Get company details ---
router.get('/:id', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const memberCheck = await pool.query(
            'SELECT role FROM company_members WHERE company_id = $1 AND user_id = $2 AND is_active = TRUE',
            [req.params.id, req.user!.id]
        );
        if (memberCheck.rows.length === 0) { res.status(403).json({ error: 'Not a member of this company' }); return; }

        const company = await pool.query('SELECT * FROM companies WHERE id = $1', [req.params.id]);
        const members = await pool.query(
            `SELECT cm.*, u.email, u.display_name FROM company_members cm
       JOIN users u ON u.id = cm.user_id WHERE cm.company_id = $1 ORDER BY cm.role, u.email`,
            [req.params.id]
        );
        const teams = await pool.query('SELECT * FROM teams WHERE company_id = $1 ORDER BY name', [req.params.id]);

        res.json({
            company: company.rows[0],
            members: members.rows,
            teams: teams.rows,
            current_role: memberCheck.rows[0].role,
        });
    } catch (err) {
        res.status(500).json({ error: 'Failed to get company' });
    }
});

// --- Add member (BR-18) ---
router.post('/:id/members', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const roleCheck = await pool.query(
            "SELECT role FROM company_members WHERE company_id = $1 AND user_id = $2 AND role IN ('owner', 'admin')",
            [req.params.id, req.user!.id]
        );
        if (roleCheck.rows.length === 0) { res.status(403).json({ error: 'Only owners/admins can add members' }); return; }

        const { email, role, storage_quota_bytes } = req.body as { email?: string; role?: string; storage_quota_bytes?: number };
        if (!email) { res.status(400).json({ error: 'Email required' }); return; }

        const userResult = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
        if (userResult.rows.length === 0) { res.status(404).json({ error: 'User not found' }); return; }

        const validRoles = ['admin', 'manager', 'employee', 'viewer'];
        const memberRole = role && validRoles.includes(role) ? role : 'employee';

        await pool.query(
            `INSERT INTO company_members (company_id, user_id, role, storage_quota_bytes)
       VALUES ($1, $2, $3, $4) ON CONFLICT (company_id, user_id) DO UPDATE SET role = $3, is_active = TRUE`,
            [req.params.id, userResult.rows[0].id, memberRole, storage_quota_bytes || 3221225472]
        );

        await logAudit({ userId: req.user!.id, companyId: req.params.id, action: 'company.add_member', req, metadata: { email, role: memberRole } });
        res.status(201).json({ success: true });
    } catch (err) {
        res.status(500).json({ error: 'Failed to add member' });
    }
});

// --- Remove / exit member (BR-COMP-10) ---
router.put('/:id/members/:userId/exit', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { id: companyId, userId } = req.params;

        const roleCheck = await pool.query(
            "SELECT role FROM company_members WHERE company_id = $1 AND user_id = $2 AND role IN ('owner', 'admin')",
            [companyId, req.user!.id]
        );
        if (roleCheck.rows.length === 0 && req.user!.id !== userId) {
            res.status(403).json({ error: 'Not authorized' }); return;
        }

        const exitingMember = await pool.query(
            'SELECT role FROM company_members WHERE company_id = $1 AND user_id = $2',
            [companyId, userId]
        );
        if (exitingMember.rows.length > 0 && exitingMember.rows[0].role === 'owner') {
            const ownerCount = await pool.query(
                "SELECT COUNT(*) FROM company_members WHERE company_id = $1 AND role = 'owner' AND is_active = TRUE",
                [companyId]
            );
            if (parseInt(ownerCount.rows[0].count) <= 1) {
                res.status(400).json({ error: 'Cannot remove the last owner. Transfer ownership first.' }); return;
            }
        }

        await pool.query(
            'UPDATE company_members SET is_active = FALSE WHERE company_id = $1 AND user_id = $2',
            [companyId, userId]
        );

        const adminResult = await pool.query(
            "SELECT user_id FROM company_members WHERE company_id = $1 AND role IN ('owner', 'admin') AND is_active = TRUE AND user_id != $2 LIMIT 1",
            [companyId, userId]
        );
        const newOwnerId = adminResult.rows.length > 0 ? adminResult.rows[0].user_id : null;

        if (newOwnerId) {
            await pool.query(
                'UPDATE files_metadata SET user_id = $1 WHERE user_id = $2 AND company_id = $3',
                [newOwnerId, userId, companyId]
            );
        }

        await pool.query(
            `UPDATE shares SET is_revoked = TRUE WHERE owner_id = $1 AND file_id IN
       (SELECT id FROM files_metadata WHERE company_id = $2)`,
            [userId, companyId]
        );

        await logAudit({ userId: req.user!.id, companyId, action: 'company.member_exit', req, metadata: { exited_user: userId } });
        res.json({ success: true });
    } catch (err) {
        console.error('Member exit error:', err);
        res.status(500).json({ error: 'Failed to process member exit' });
    }
});

// --- Create team (BR-COMP-05) ---
router.post('/:id/teams', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const roleCheck = await pool.query(
            "SELECT role FROM company_members WHERE company_id = $1 AND user_id = $2 AND role IN ('owner', 'admin', 'manager')",
            [req.params.id, req.user!.id]
        );
        if (roleCheck.rows.length === 0) { res.status(403).json({ error: 'Not authorized' }); return; }

        const { name, storage_quota_bytes } = req.body as { name?: string; storage_quota_bytes?: number };
        if (!name) { res.status(400).json({ error: 'Team name required' }); return; }

        const result = await pool.query(
            'INSERT INTO teams (company_id, name, storage_quota_bytes) VALUES ($1, $2, $3) RETURNING *',
            [req.params.id, name, storage_quota_bytes || 10737418240]
        );

        await logAudit({ userId: req.user!.id, companyId: req.params.id, action: 'team.create', resourceType: 'team', resourceId: result.rows[0].id, req });
        res.status(201).json(result.rows[0]);
    } catch (err: unknown) {
        const pgErr = err as { code?: string };
        if (pgErr.code === '23505') { res.status(409).json({ error: 'Team name already exists in this company' }); return; }
        res.status(500).json({ error: 'Failed to create team' });
    }
});

// --- Add team member ---
router.post('/:id/teams/:teamId/members', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { user_id } = req.body as { user_id?: string };
        if (!user_id) { res.status(400).json({ error: 'user_id required' }); return; }

        await pool.query(
            'INSERT INTO team_members (team_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
            [req.params.teamId, user_id]
        );

        res.status(201).json({ success: true });
    } catch (err) {
        res.status(500).json({ error: 'Failed to add team member' });
    }
});

// --- Update company ---
router.put('/:id', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const roleCheck = await pool.query(
            "SELECT role FROM company_members WHERE company_id = $1 AND user_id = $2 AND role IN ('owner', 'admin')",
            [req.params.id, req.user!.id]
        );
        if (roleCheck.rows.length === 0) { res.status(403).json({ error: 'Not authorized' }); return; }

        const { name, official_email, is_verified, verification_type } = req.body;
        const result = await pool.query(
            `UPDATE companies SET
         name = COALESCE($1, name),
         official_email = COALESCE($2, official_email),
         is_verified = COALESCE($3, is_verified),
         verification_type = COALESCE($4, verification_type)
       WHERE id = $5 RETURNING *`,
            [name, official_email, is_verified, verification_type, req.params.id]
        );

        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: 'Failed to update company' });
    }
});

// --- Delete member ---
router.delete('/:id/members/:userId', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const roleCheck = await pool.query(
            "SELECT role FROM company_members WHERE company_id = $1 AND user_id = $2 AND role IN ('owner', 'admin')",
            [req.params.id, req.user!.id]
        );
        if (roleCheck.rows.length === 0) { res.status(403).json({ error: 'Not authorized' }); return; }

        await pool.query(
            'DELETE FROM company_members WHERE company_id = $1 AND user_id = $2',
            [req.params.id, req.params.userId]
        );
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: 'Failed to remove member' });
    }
});

export default router;
