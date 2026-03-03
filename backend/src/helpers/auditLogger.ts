// ============================================================
// PriVault – Audit Logger Helper
// ============================================================

import { pool } from '../config/db';
import { AuditLogParams } from '../types';

export async function logAudit({ userId, companyId, action, resourceType, resourceId, req, metadata }: AuditLogParams): Promise<void> {
    try {
        const ip = req?.deviceInfo?.ip || req?.socket?.remoteAddress || 'unknown';
        const deviceType = req?.deviceInfo?.device_type || 'unknown';
        await pool.query(
            `INSERT INTO audit_logs (user_id, company_id, action, resource_type, resource_id, ip_address, device_type, metadata)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
            [userId, companyId || null, action, resourceType || null, resourceId || null, ip, deviceType, JSON.stringify(metadata || {})]
        );
    } catch (err: unknown) {
        const message = err instanceof Error ? err.message : String(err);
        console.error('Audit log failed:', message);
    }
}
