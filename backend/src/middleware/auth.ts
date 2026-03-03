// ============================================================
// PriVault – Auth Middleware
// ============================================================

import { Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { AuthRequest } from '../types';

export function authMiddleware(req: AuthRequest, res: Response, next: NextFunction): void {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).json({ error: 'Authentication required' });
        return;
    }

    const token = authHeader.split(' ')[1];
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET as string) as {
            id: string;
            email: string;
            account_type: 'regular' | 'company';
        };
        req.user = decoded;
        next();
    } catch (err) {
        res.status(401).json({ error: 'Invalid or expired token' });
    }
}

export function generateToken(user: { id: string; email: string; account_type: string }): string {
    return jwt.sign(
        { id: user.id, email: user.email, account_type: user.account_type },
        process.env.JWT_SECRET as string,
        { expiresIn: '7d' }
    );
}
