// ============================================================
// PriVault – Email Service (OTP / Notifications)
// ============================================================

import nodemailer, { Transporter } from 'nodemailer';

let transporter: Transporter | null = null;

function getTransporter(): Transporter {
    if (!transporter) {
        transporter = nodemailer.createTransport({
            host: process.env.SMTP_HOST || 'smtp.gmail.com',
            port: parseInt(process.env.SMTP_PORT || '587', 10),
            secure: false,
            auth: {
                user: process.env.SMTP_USER,
                pass: process.env.SMTP_PASS,
            },
        });
    }
    return transporter;
}

export async function sendOtpEmail(to: string, code: string): Promise<void> {
    const mail = getTransporter();
    await mail.sendMail({
        from: `"PriVault" <${process.env.SMTP_USER}>`,
        to,
        subject: 'PriVault – Your Verification Code',
        html: `
      <div style="font-family: Arial, sans-serif; max-width: 400px; margin: 0 auto; padding: 24px; border: 1px solid #e0e0e0; border-radius: 12px;">
        <h2 style="color: #6C63FF;">PriVault Verification</h2>
        <p>Your one-time verification code is:</p>
        <div style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #6C63FF; padding: 16px 0;">${code}</div>
        <p style="color: #888; font-size: 12px;">This code expires in 10 minutes. Do not share it.</p>
      </div>
    `,
    });
}

export async function sendNotificationEmail(to: string, subject: string, message: string): Promise<void> {
    const mail = getTransporter();
    await mail.sendMail({
        from: `"PriVault" <${process.env.SMTP_USER}>`,
        to,
        subject: `PriVault – ${subject}`,
        html: `<div style="font-family: Arial, sans-serif; padding: 24px;"><p>${message}</p></div>`,
    });
}
