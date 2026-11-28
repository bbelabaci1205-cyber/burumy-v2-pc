// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! App lock for the Flutter app. The lock file is plain JSON the app keeps
//! in the phone keychain; every call hands back the updated file.

use anyhow::Result;
use burumy_engine::lock::{password_ok, LockFile, Role};

pub struct LockOutcome {
    /// Save this (wrong tries are counted inside).
    pub file: String,
    /// "normal", "hide", "delete", "account" or None (wrong password).
    pub role: Option<String>,
    pub fails: u32,
    /// The wrong-try limit was reached: erase every chat now.
    pub wipe: bool,
}

pub(crate) fn role_name(r: Role) -> String {
    match r {
        Role::Normal => "normal",
        Role::Hide => "hide",
        Role::Delete => "delete",
        Role::Account => "account",
    }
    .into()
}

pub(crate) fn role_from(name: &str) -> Role {
    match name {
        "hide" => Role::Hide,
        "delete" => Role::Delete,
        "account" => Role::Account,
        _ => Role::Normal,
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn lock_password_ok(pw: String) -> bool {
    password_ok(&pw)
}

pub fn lock_new(normal: String) -> Result<String> {
    Ok(LockFile::new(&normal)?.to_json())
}

pub fn lock_unlock(file: String, pw: String) -> Result<LockOutcome> {
    let mut f = LockFile::from_json(&file)?;
    let role = f.unlock(&pw).map(role_name);
    let fails = f.fails;
    let wipe = role.is_none() && f.take_wipe();
    Ok(LockOutcome { file: f.to_json(), role, fails, wipe })
}

/// Sets (pw = Some) or removes (None) the hide or delete password.
pub fn lock_set_extra(file: String, normal: String, role: String, pw: Option<String>) -> Result<String> {
    let mut f = LockFile::from_json(&file)?;
    f.set_extra(&normal, role_from(&role), pw.as_deref())?;
    Ok(f.to_json())
}

/// [hide set, delete set, account set] — needs the normal password.
pub fn lock_extras(file: String, normal: String) -> Result<Vec<bool>> {
    let mut f = LockFile::from_json(&file)?;
    Ok(f.extras(&normal)?.to_vec())
}

pub fn lock_change_normal(file: String, old: String, new: String) -> Result<String> {
    let mut f = LockFile::from_json(&file)?;
    f.change_normal(&old, &new)?;
    Ok(f.to_json())
}

/// How many wrong tries erase everything (5 or 10).
#[flutter_rust_bridge::frb(sync)]
pub fn lock_wipe_after(file: String) -> u32 {
    LockFile::from_json(&file).map(|f| f.wipe_after).unwrap_or(10)
}

pub fn lock_set_wipe_after(file: String, normal: String, n: u32) -> Result<String> {
    let mut f = LockFile::from_json(&file)?;
    f.set_wipe_after(&normal, n)?;
    Ok(f.to_json())
}
