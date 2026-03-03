// ============================================================
// PriVault – Audit Log Routes (BR-16, BR-17, BR-COMP-13)
// ============================================================

import { Router, Response } from 'express';
import { pool } from '../config/db';
import { authMiddleware } from '../middleware/auth';
import { AuthRequest } from '../types';

const router = Router();

// --- Get audit logs ---
router.get('/', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { company_id, resource_type, limit: qLimit, offset } = req.query;
        const lim = Math.min(parseInt((qLimit as string) || '100', 10), 500);
        const off = parseInt((offset as string) || '0', 10);

        let query: string;
        let params: (string | number)[];

        if (company_id) {
            const roleCheck = await pool.query(
                "SELECT role FROM company_members WHERE company_id = $1 AND user_id = $2 AND role IN ('owner', 'admin', 'manager')",
                [company_id as string, req.user!.id]
            );
            if (roleCheck.rows.length === 0) { res.status(403).json({ error: 'Not authorized' }); return; }

            query = `SELECT al.*, u.email FROM audit_logs al
         JOIN users u ON u.id = al.user_id
         WHERE al.company_id = $1`;
            params = [company_id as string];

            if (resource_type) {
                query += ' AND al.resource_type = $' + (params.length + 1);
                params.push(resource_type as string);
            }
        } else {
            query = `SELECT al.*, u.email FROM audit_logs al
         JOIN users u ON u.id = al.user_id
         WHERE al.user_id = $1`;
            params = [req.user!.id];
        }

        query += ` ORDER BY al.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
        params.push(lim, off);

        const result = await pool.query(query, params);
        res.json(result.rows);
    } catch (err) {
        console.error('Audit log error:', err);
        res.status(500).json({ error: 'Failed to get audit logs' });
    }
});

// --- Export CSV (BR-17) ---
router.get('/export', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { company_id } = req.query;
        if (!company_id) { res.status(400).json({ error: 'company_id required for CSV export' }); return; }

        const roleCheck = await pool.query(
            "SELECT role FROM company_members WHERE company_id = $1 AND user_id = $2 AND role IN ('owner', 'admin')",
            [company_id as string, req.user!.id]
        );
        if (roleCheck.rows.length === 0) { res.status(403).json({ error: 'Not authorized' }); return; }

        const result = await pool.query(
            `SELECT al.action, al.resource_type, al.resource_id, al.ip_address, al.device_type, al.region, al.created_at, u.email
       FROM audit_logs al JOIN users u ON u.id = al.user_id
       WHERE al.company_id = $1 ORDER BY al.created_at DESC`,
            [company_id as string]
        );

        const header = 'Email,Action,Resource Type,Resource ID,IP Address,Device Type,Region,Timestamp\n';
        const rows = result.rows.map((r: Record<string, unknown>) =>
            `"${r.email}","${r.action}","${r.resource_type || ''}","${r.resource_id || ''}","${r.ip_address || ''}","${r.device_type || ''}","${r.region || ''}","${r.created_at}"`
        ).join('\n');

        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', 'attachment; filename=audit_logs.csv');
        res.send(header + rows);
    } catch (err) {
        res.status(500).json({ error: 'Failed to export audit logs' });
    }
});

export default router;
