// ============================================================
// PriVault – Device Info Middleware
// ============================================================

import { Response, NextFunction } from 'express';
import { AuthRequest, DeviceInfo } from '../types';

export function deviceInfoMiddleware(req: AuthRequest, _res: Response, next: NextFunction): void {
    const ip =
        (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() ||
        req.socket?.remoteAddress ||
        'unknown';

    const userAgent = req.headers['user-agent'] || 'unknown';

    let deviceType = 'unknown';
    if (/mobile/i.test(userAgent)) deviceType = 'mobile';
    else if (/tablet/i.test(userAgent)) deviceType = 'tablet';
    else if (/bot|crawl|spider/i.test(userAgent)) deviceType = 'bot';
    else deviceType = 'desktop';

    const deviceInfo: DeviceInfo = {
        ip,
        device_type: deviceType,
        user_agent: userAgent,
    };

    req.deviceInfo = deviceInfo;
    next();
}
