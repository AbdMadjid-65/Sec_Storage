// ============================================================
// PriVault – Email Service (uses Resend — works on Render free tier)
// ============================================================

import { Resend } from 'resend';

function getClient(): Resend {
    const apiKey = process.env.RESEND_API_KEY;
    if (!apiKey) throw new Error('RESEND_API_KEY is not set in environment variables');
    return new Resend(apiKey);
}

async function sendMail(to: string, subject: string, html: string): Promise<void> {
    const resend = getClient();

    // Use your verified domain if you have one, otherwise use Resend's test address
    // NOTE: with onboarding@resend.dev you can only send to your OWN email (the one you signed up with)
    // To send to ANY email, verify a domain at resend.com/domains
    const fromAddress = process.env.RESEND_FROM || 'PriVault <onboarding@resend.dev>';

    const { error } = await resend.emails.send({
        from: fromAddress,
        to,
        subject,
        html,
    });

    if (error) {
        console.error('❌ Resend email failed:', error);
        throw new Error(`Email send failed: ${error.message}`);
    }

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