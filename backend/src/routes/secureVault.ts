// ============================================================
// PriVault – Secure Vault Routes (BR-11, BR-COMP-15)
// ============================================================

import { Router, Response } from 'express';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { pool } from '../config/db';
import { authMiddleware } from '../middleware/auth';
import { sendOtpEmail } from '../helpers/emailService';
import { logAudit } from '../helpers/auditLogger';
import { AuthRequest } from '../types';

const router = Router();

// --- Verify 2FA for vault access (BR-11) ---
router.post('/verify-2fa', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { code } = req.body as { code?: string };

        if (!code) {
            const otp = crypto.randomInt(100000, 999999).toString();
            const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

            await pool.query(
                'INSERT INTO otp_codes (user_id, code, type, expires_at) VALUES ($1, $2, $3, $4)',
                [req.user!.id, otp, 'email', expiresAt]
            );

            const userResult = await pool.query('SELECT email FROM users WHERE id = $1', [req.user!.id]);
            try { await sendOtpEmail(userResult.rows[0].email, otp); } catch (e) { console.error('Vault OTP email failed:', e); }

            res.json({ message: 'Verification code sent', sent: true });
            return;
        }

        const otpResult = await pool.query(
            `SELECT id FROM otp_codes WHERE user_id = $1 AND code = $2 AND used = FALSE AND expires_at > NOW()
       ORDER BY created_at DESC LIMIT 1`,
            [req.user!.id, code]
        );

        if (otpResult.rows.length === 0) {
            res.status(401).json({ error: 'Invalid or expired code' });
            return;
        }

        await pool.query('UPDATE otp_codes SET used = TRUE WHERE id = $1', [otpResult.rows[0].id]);
        await logAudit({ userId: req.user!.id, action: 'vault.access', req });

        const vaultToken = jwt.sign(
            { id: req.user!.id, vault_access: true },
            process.env.JWT_SECRET as string,
            { expiresIn: '5m' }
        );

        res.json({ vault_token: vaultToken, expires_in: 300 });
    } catch (err) {
        console.error('Vault 2FA error:', err);
        res.status(500).json({ error: 'Vault verification failed' });
    }
});

// --- List vault files ---
router.get('/files', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const result = await pool.query(
            'SELECT * FROM files_metadata WHERE user_id = $1 AND is_vault_file = TRUE AND is_deleted = FALSE ORDER BY created_at DESC',
            [req.user!.id]
        );
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: 'Failed to list vault files' });
    }
});

export default router;
