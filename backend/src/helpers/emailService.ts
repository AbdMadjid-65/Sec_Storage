// ============================================================
// PriVault – Email Service (OTP / Notifications)
// ============================================================

import nodemailer from 'nodemailer';

// FIX: Do NOT cache the transporter at module level.
// If env vars aren't loaded yet, or SMTP fails, a cached transporter
// will silently reuse broken credentials forever.
function createTransporter() {
    const host = process.env.SMTP_HOST || 'smtp.gmail.com';
    const port = parseInt(process.env.SMTP_PORT || '587', 10);
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASS;

    if (!user || !pass) {
        throw new Error('SMTP_USER and SMTP_PASS must be set in environment variables');
    }

    return nodemailer.createTransport({
        host,
        port,
        // FIX: port 465 = secure:true (SSL), port 587 = secure:false (STARTTLS)
        // Keep false for 587, but add tls options to handle Render's network
        secure: port === 465,
        auth: { user, pass },
        tls: {
            // FIX: Render and some cloud providers have strict TLS — this prevents
            // "self signed certificate" or "UNABLE_TO_VERIFY_LEAF_SIGNATURE" errors
            rejectUnauthorized: false,
        },
        // FIX: Increased timeouts for Render's cold-start latency
        connectionTimeout: 10000,
        greetingTimeout: 10000,
        socketTimeout: 15000,
    });
}

async function sendMail(to: string, subject: string, html: string): Promise<void> {
    const transporter = createTransporter();

    // FIX: Verify connection before sending — gives a clear error instead of silent failure
    try {
        await transporter.verify();
    } catch (verifyErr) {
        console.error('❌ SMTP connection verification failed:', verifyErr);
        throw new Error(`SMTP connection failed: ${(verifyErr as Error).message}`);
    }

    await transporter.sendMail({
        from: `"PriVault" <${process.env.SMTP_USER}>`,
        to,
        subject,
        html,
    });

    console.log(`✅ Email sent to ${to} — subject: "${subject}"`);
}

export async function sendOtpEmail(to: string, code: string): Promise<void> {
    await sendMail(
        to,
        'PriVault – Your Verification Code',
        `
        <div style="font-family: Arial, sans-serif; max-width: 400px; margin: 0 auto; padding: 24px;
                    border: 1px solid #e0e0e0; border-radius: 12px;">
            <h2 style="color: #6C63FF;">PriVault Verification</h2>
            <p>Your one-time verification code is:</p>
            <div style="font-size: 32px; font-weight: bold; letter-spacing: 8px;
                        color: #6C63FF; padding: 16px 0;">${code}</div>
            <p style="color: #888; font-size: 12px;">This code expires in 10 minutes. Do not share it.</p>
        </div>
        `
    );
}

export async function sendPasswordResetEmail(to: string, code: string): Promise<void> {
    await sendMail(
        to,
        'PriVault – Password Reset Code',
        `
        <div style="font-family: Arial, sans-serif; max-width: 400px; margin: 0 auto; padding: 24px;
                    border: 1px solid #e0e0e0; border-radius: 12px;">
            <h2 style="color: #6C63FF;">Password Reset</h2>
            <p>You requested to reset your PriVault password. Use the code below:</p>
            <div style="font-size: 32px; font-weight: bold; letter-spacing: 8px;
                        color: #6C63FF; padding: 16px 0;">${code}</div>
            <p style="color: #888; font-size: 12px;">
                This code expires in 10 minutes. If you didn't request this, ignore this email.
            </p>
        </div>
        `
    );
}

export async function sendNotificationEmail(
    to: string,
    subject: string,
    message: string
): Promise<void> {
    await sendMail(
        to,
        subject,
        `<div style="font-family: Arial, sans-serif; padding: 24px;"><p>${message}</p></div>`
    );
}