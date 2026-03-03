// ============================================================
// PriVault – Auth Routes
// ============================================================

import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { pool } from '../config/db';
import { authMiddleware, generateToken } from '../middleware/auth';
import { sendOtpEmail } from '../helpers/emailService';
import { logAudit } from '../helpers/auditLogger';
import { AuthRequest } from '../types';

const router = Router();

function validatePassword(password: string): string | null {
    if (!password || password.length < 10) return 'Password must be at least 10 characters';
    if (!/[A-Z]/.test(password)) return 'Password must contain an uppercase letter';
    if (!/[a-z]/.test(password)) return 'Password must contain a lowercase letter';
    if (!/[0-9]/.test(password)) return 'Password must contain a number';
    if (!/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)) return 'Password must contain a special character';
    return null;
}

// --- Register (BR-01, BR-03) ---
router.post('/register', async (req: Request, res: Response): Promise<void> => {
    try {
        const { email, password, account_type, salt, public_key } = req.body;
        if (!email || !password) { res.status(400).json({ error: 'Email and password required' }); return; }

        const pwError = validatePassword(password);
        if (pwError) { res.status(400).json({ error: pwError }); return; }

        const type = account_type === 'company' ? 'company' : 'regular';

        const existing = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
        if (existing.rows.length > 0) { res.status(409).json({ error: 'Email already registered' }); return; }

        const passwordHash = await bcrypt.hash(password, 12);
        const result = await pool.query(
            `INSERT INTO users (email, password_hash, account_type, salt, public_key)
       VALUES ($1, $2, $3, $4, $5) RETURNING id, email, account_type, storage_max_bytes, created_at`,
            [email, passwordHash, type, salt || null, public_key || null]
        );

        const user = result.rows[0];
        const token = generateToken(user);
        await logAudit({ userId: user.id, action: 'auth.register', req: req as AuthRequest });

        res.status(201).json({ user, token });
    } catch (err) {
        console.error('Register error:', err);
        res.status(500).json({ error: 'Registration failed' });
    }
});

// --- Login (BR-02) ---
router.post('/login', async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { email, password, device_fingerprint, device_name, device_type } = req.body;
        if (!email || !password) { res.status(400).json({ error: 'Email and password required' }); return; }

        const result = await pool.query(
            'SELECT id, email, password_hash, salt, public_key, account_type, is_2fa_enabled, storage_used_bytes, storage_max_bytes FROM users WHERE email = $1',
            [email]
        );
        if (result.rows.length === 0) { res.status(401).json({ error: 'Invalid credentials' }); return; }

        const user = result.rows[0];
        const validPassword = await bcrypt.compare(password, user.password_hash);
        if (!validPassword) { res.status(401).json({ error: 'Invalid credentials' }); return; }

        if (user.is_2fa_enabled && device_fingerprint) {
            const trusted = await pool.query(
                'SELECT id FROM trusted_devices WHERE user_id = $1 AND device_fingerprint = $2',
                [user.id, device_fingerprint]
            );

            if (trusted.rows.length === 0) {
                const otp = crypto.randomInt(100000, 999999).toString();
                const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

                await pool.query(
                    'INSERT INTO otp_codes (user_id, code, type, expires_at) VALUES ($1, $2, $3, $4)',
                    [user.id, otp, 'email', expiresAt]
                );

                try { await sendOtpEmail(user.email, otp); } catch (emailErr) { console.error('OTP email send failed:', emailErr); }

                res.status(200).json({
                    requires_2fa: true,
                    user_id: user.id,
                    message: 'Verification code sent to your email',
                });
                return;
            }
        }

        const token = generateToken(user);
        await logAudit({ userId: user.id, action: 'auth.login', req });

        res.json({ user: { ...user, password_hash: undefined }, token });
    } catch (err) {
        console.error('Login error:', err);
        res.status(500).json({ error: 'Login failed' });
    }
});

// --- Verify 2FA (BR-02) ---
router.post('/verify-2fa', async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { user_id, code, device_fingerprint, device_name, device_type } = req.body;
        if (!user_id || !code) { res.status(400).json({ error: 'User ID and code required' }); return; }

        const otpResult = await pool.query(
            `SELECT id FROM otp_codes
       WHERE user_id = $1 AND code = $2 AND used = FALSE AND expires_at > NOW()
       ORDER BY created_at DESC LIMIT 1`,
            [user_id, code]
        );
        if (otpResult.rows.length === 0) { res.status(401).json({ error: 'Invalid or expired code' }); return; }

        await pool.query('UPDATE otp_codes SET used = TRUE WHERE id = $1', [otpResult.rows[0].id]);

        if (device_fingerprint) {
            await pool.query(
                `INSERT INTO trusted_devices (user_id, device_fingerprint, device_name, device_type, ip_address)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (user_id, device_fingerprint) DO UPDATE SET device_name = $3`,
                [user_id, device_fingerprint, device_name || 'Unknown', device_type || 'unknown', req.deviceInfo?.ip || 'unknown']
            );
        }

        const userResult = await pool.query(
            'SELECT id, email, account_type, salt, public_key, storage_used_bytes, storage_max_bytes FROM users WHERE id = $1',
            [user_id]
        );
        const user = userResult.rows[0];
        const token = generateToken(user);

        await logAudit({ userId: user.id, action: 'auth.verify_2fa', req });

        res.json({ user, token });
    } catch (err) {
        console.error('2FA verify error:', err);
        res.status(500).json({ error: 'Verification failed' });
    }
});

// --- Trust Device ---
router.post('/trust-device', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { device_fingerprint, device_name, device_type } = req.body;
        if (!device_fingerprint) { res.status(400).json({ error: 'Device fingerprint required' }); return; }

        await pool.query(
            `INSERT INTO trusted_devices (user_id, device_fingerprint, device_name, device_type, ip_address)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (user_id, device_fingerprint) DO NOTHING`,
            [req.user!.id, device_fingerprint, device_name, device_type, req.deviceInfo?.ip]
        );

        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: 'Failed to trust device' });
    }
});

// --- Logout ---
router.post('/logout', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    await logAudit({ userId: req.user!.id, action: 'auth.logout', req });
    res.json({ success: true });
});

export default router;
