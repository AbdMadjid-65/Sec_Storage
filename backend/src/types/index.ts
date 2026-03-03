// ============================================================
// PriVault – Shared TypeScript Types
// ============================================================

import { Request } from 'express';

export interface AuthRequest extends Request {
    user?: {
        id: string;
        email: string;
        account_type: 'regular' | 'company';
    };
    deviceInfo?: DeviceInfo;
}

export interface DeviceInfo {
    ip: string;
    device_type: string;
    user_agent: string;
    region?: string;
}

export interface User {
    id: string;
    email: string;
    password_hash: string;
    account_type: 'regular' | 'company';
    salt?: string;
    public_key?: string;
    storage_used_bytes: number;
    storage_max_bytes: number;
    is_2fa_enabled: boolean;
    created_at: Date;
}

export interface FileMetadata {
    id: string;
    user_id: string;
    company_id?: string;
    team_id?: string;
    folder_id?: string;
    name: string;
    encrypted_name: string;
    size_bytes: number;
    storage_path: string;
    file_key_encrypted?: string;
    is_favorite: boolean;
    is_deleted: boolean;
    deleted_at?: Date;
    is_vault_file: boolean;
    created_at: Date;
    updated_at: Date;
}

export interface FolderRecord {
    id: string;
    user_id: string;
    parent_id?: string;
    name: string;
    created_at: Date;
}

export interface Share {
    id: string;
    owner_id: string;
    file_id?: string;
    folder_id?: string;
    type: 'link' | 'user' | 'team';
    encrypted_key?: string;
    permission: 'view' | 'download' | 'edit';
    expires_at?: Date;
    max_downloads: number;
    download_count: number;
    is_revoked: boolean;
    shared_with_team_id?: string;
    created_at: Date;
}

export interface Company {
    id: string;
    name: string;
    official_email: string;
    owner_id: string;
    is_verified: boolean;
    verification_type?: string;
    storage_used_bytes: number;
    storage_max_bytes: number;
    created_at: Date;
}

export interface CompanyMember {
    id: string;
    company_id: string;
    user_id: string;
    role: 'owner' | 'admin' | 'manager' | 'employee' | 'viewer';
    storage_quota_bytes: number;
    is_active: boolean;
    created_at: Date;
}

export interface Team {
    id: string;
    company_id: string;
    name: string;
    created_at: Date;
}

export interface AuditLog {
    id: string;
    company_id?: string;
    user_id: string;
    action: string;
    resource_type?: string;
    resource_id?: string;
    ip_address: string;
    device_type: string;
    region?: string;
    metadata?: Record<string, unknown>;
    created_at: Date;
}

export interface Comment {
    id: string;
    file_id: string;
    user_id: string;
    content: string;
    created_at: Date;
    updated_at: Date;
}

export interface PapersWalletItem {
    id: string;
    user_id: string;
    type: string;
    encrypted_data: string;
    label?: string;
    created_at: Date;
    updated_at: Date;
}

export interface AuditLogParams {
    userId: string;
    companyId?: string | null;
    action: string;
    resourceType?: string | null;
    resourceId?: string | null;
    req?: AuthRequest;
    metadata?: Record<string, unknown>;
}
