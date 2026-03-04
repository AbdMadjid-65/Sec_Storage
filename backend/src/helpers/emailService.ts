// ============================================================
// PriVault – Email Service (Brevo SMTP — works on Render free tier)
// ============================================================

import nodemailer from 'nodemailer';

function createTransporter() {
    const host = process.env.SMTP_HOST || 'smtp-relay.brevo.com';
    const port = parseInt(process.env.SMTP_PORT || '587', 10);
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASS;

    if (!user || !pass) {
        throw new Error('SMTP_USER and SMTP_PASS must be set in environment variables');
    }

    return nodemailer.createTransport({
        host,
        port,
        secure: false,
        auth: { user, pass },
        tls: { rejectUnauthorized: false },
        connectionTimeout: 10000,
        greetingTimeout: 10000,
        socketTimeout: 15000,
    });
}

async function sendMail(to: string, subject: string, html: string): Promise<void> {
    const transporter = createTransporter();

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