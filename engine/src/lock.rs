// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! App lock with three passwords: normal, hide, delete.
//!
//! There are always three slots, so the file looks the same whether 1, 2
//! or 3 passwords are set (unused slots hold random decoys). Unlocking
//! always does the same work for all three slots, so the time taken does
//! not tell which password was typed. Which slot plays which role is
//! itself hidden: each slot's role byte is masked with a key that only
//! that slot's password produces, and the map of the hide/delete slots is
//! masked with the normal password's key.

use anyhow::{Result, bail};
use argon2::{Algorithm, Argon2, Params, Version};
use rand::{RngCore, rngs::OsRng};
use serde::{Deserialize, Serialize};
use zeroize::Zeroize;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Role {
    Normal = 0,
    Hide = 1,
    Delete = 2,
    /// Erases the accounts chosen beforehand from this phone (only when
    /// two or more accounts are on it; Eric 2026-11-27).
    Account = 3,
}

impl Role {
    fn from_u8(v: u8) -> Option<Role> {
        match v {
            0 => Some(Role::Normal),
            1 => Some(Role::Hide),
            2 => Some(Role::Delete),
            3 => Some(Role::Account),
            _ => None,
        }
    }
}

/// Bytes are written as fixed-width hex so every lock file has the same shape.
mod byte_hex {
    use serde::{Deserialize, Deserializer, Serializer};
    pub fn serialize<S: Serializer, const N: usize>(v: &[u8; N], s: S) -> Result<S::Ok, S::Error> {
        s.serialize_str(&super::hex(v))
    }
    pub fn deserialize<'de, D: Deserializer<'de>, const N: usize>(
        d: D,
    ) -> Result<[u8; N], D::Error> {
        let v = super::unhex(&String::deserialize(d)?);
        v.try_into()
            .map_err(|_| serde::de::Error::custom("bad length"))
    }
}

#[derive(Clone, Serialize, Deserialize)]
struct Slot {
    salt: String,
    check: String,
    #[serde(with = "byte_hex")]
    role: [u8; 1],
}

/// Saved as JSON by the app (phone keychain / browser storage).
/// Four slots: normal, hide, delete, account (unused ones hold random
/// decoys, so every lock file has the same shape).
const SLOTS: usize = 4;
/// "Not set" in the role map.
const UNSET: u8 = 4;

#[derive(Clone, Serialize, Deserialize)]
pub struct LockFile {
    /// Older files (before the account password) have three slots; they
    /// get a fourth decoy when read.
    slots: Vec<Slot>,
    /// Which slots are hide / delete / account, masked by the normal key.
    /// Older files: two entries with 3 = not set (upgraded on the next
    /// change made with the normal password).
    map: String,
    /// Wrong tries in a row.
    pub fails: u32,
    /// After this many wrong tries in a row, every chat on this phone is
    /// erased (5 or 10; 10 by default).
    #[serde(default = "default_wipe_after")]
    pub wipe_after: u32,
}

fn default_wipe_after() -> u32 {
    10
}

/// 8+ characters with at least one letter and one digit (rulebook).
pub fn password_ok(pw: &str) -> bool {
    pw.chars().count() >= 8
        && pw.chars().any(|c| c.is_alphabetic())
        && pw.chars().any(|c| c.is_ascii_digit())
}

fn hex(b: &[u8]) -> String {
    b.iter().map(|x| format!("{x:02x}")).collect()
}

fn unhex(s: &str) -> Vec<u8> {
    (0..s.len() / 2)
        .filter_map(|i| u8::from_str_radix(&s[i * 2..i * 2 + 2], 16).ok())
        .collect()
}

/// 64 bytes: [0..32] = what we compare, [32..64] = mask key.
fn derive(pw: &str, salt: &[u8]) -> [u8; 64] {
    let params = Params::new(19 * 1024, 2, 1, Some(64)).expect("argon2 params");
    let mut out = [0u8; 64];
    Argon2::new(Algorithm::Argon2id, Version::V0x13, params)
        .hash_password_into(pw.as_bytes(), salt, &mut out)
        .expect("argon2");
    out
}

fn random<const N: usize>() -> [u8; N] {
    let mut b = [0u8; N];
    OsRng.fill_bytes(&mut b);
    b
}

fn decoy() -> Slot {
    Slot {
        salt: hex(&random::<16>()),
        check: hex(&random::<32>()),
        role: random::<1>(),
    }
}

fn make(pw: &str, role: Role) -> (Slot, [u8; 64]) {
    let salt = random::<16>();
    let k = derive(pw, &salt);
    (
        Slot {
            salt: hex(&salt),
            check: hex(&k[..32]),
            role: [role as u8 ^ k[32]],
        },
        k,
    )
}

fn same(a: &[u8], b: &[u8]) -> bool {
    a.len() == b.len() && a.iter().zip(b).fold(0u8, |acc, (x, y)| acc | (x ^ y)) == 0
}

impl LockFile {
    pub fn new(normal: &str) -> Result<LockFile> {
        if !password_ok(normal) {
            bail!("password rule");
        }
        let at = (random::<1>()[0] as usize) % SLOTS;
        let mut slots: Vec<Slot> = (0..SLOTS).map(|_| decoy()).collect();
        let (s, mut k) = make(normal, Role::Normal);
        slots[at] = s;
        let map = hex(&[UNSET ^ k[33], UNSET ^ k[34], UNSET ^ k[35]]);
        k.zeroize();
        Ok(LockFile {
            slots,
            map,
            fails: 0,
            wipe_after: default_wipe_after(),
        })
    }

    pub fn from_json(s: &str) -> Result<LockFile> {
        let mut f: LockFile = serde_json::from_str(s)?;
        while f.slots.len() < SLOTS {
            f.slots.push(decoy());
        }
        Ok(f)
    }

    /// Role map in the clear: slot of hide, delete, account (UNSET = none).
    fn roles(&self, nk: &[u8; 64]) -> [u8; 3] {
        let m = unhex(&self.map);
        if m.len() == 2 {
            // Older file: 3 meant "not set", no account entry.
            let old = |v: u8| if v >= 3 { UNSET } else { v };
            return [old(m[0] ^ nk[33]), old(m[1] ^ nk[34]), UNSET];
        }
        [m[0] ^ nk[33], m[1] ^ nk[34], m.get(2).map_or(UNSET, |v| v ^ nk[35])]
    }

    fn set_roles(&mut self, r: [u8; 3], nk: &[u8; 64]) {
        self.map = hex(&[r[0] ^ nk[33], r[1] ^ nk[34], r[2] ^ nk[35]]);
    }

    pub fn to_json(&self) -> String {
        serde_json::to_string(self).unwrap_or_default()
    }

    /// Tries every slot (always all of them). Returns the role and the
    /// slot's key, or None (and counts a failure).
    fn open(&mut self, pw: &str) -> Option<(Role, usize, [u8; 64])> {
        let mut hit = None;
        for (i, s) in self.slots.iter().enumerate() {
            let k = derive(pw, &unhex(&s.salt));
            if same(&k[..32], &unhex(&s.check)) && hit.is_none() {
                if let Some(r) = Role::from_u8(s.role[0] ^ k[32]) {
                    hit = Some((r, i, k));
                }
            }
        }
        match hit {
            Some(_) => self.fails = 0,
            None => self.fails += 1,
        }
        hit
    }

    /// The wrong-try limit was just reached: erase everything now. Counting
    /// starts again afterwards.
    pub fn take_wipe(&mut self) -> bool {
        if self.wipe_after > 0 && self.fails >= self.wipe_after {
            self.fails = 0;
            return true;
        }
        false
    }

    /// 5 or 10 wrong tries before erasing (needs the normal password).
    pub fn set_wipe_after(&mut self, normal: &str, n: u32) -> Result<()> {
        if n != 5 && n != 10 {
            bail!("5 or 10");
        }
        let Some((Role::Normal, _, mut k)) = self.open(normal) else {
            bail!("wrong password")
        };
        k.zeroize();
        self.wipe_after = n;
        Ok(())
    }

    pub fn unlock(&mut self, pw: &str) -> Option<Role> {
        self.open(pw).map(|(r, _, mut k)| {
            k.zeroize();
            r
        })
    }

    /// Sets (or replaces) the hide or delete password. Needs the normal one.
    /// `pw` = None removes that password.
    pub fn set_extra(&mut self, normal: &str, role: Role, pw: Option<&str>) -> Result<()> {
        if role == Role::Normal {
            bail!("use change_normal");
        }
        let Some((Role::Normal, ni, mut nk)) = self.open(normal) else {
            bail!("wrong password")
        };
        if let Some(p) = pw {
            if !password_ok(p) {
                bail!("password rule");
            }
            if self.clone().unlock(p).is_some() {
                bail!("password already used");
            }
        }
        let mut map = self.roles(&nk);
        let idx = role as usize - 1;
        let slot = if map[idx] < UNSET {
            map[idx] as usize
        } else {
            // A free decoy slot: not normal, not another role.
            (0..SLOTS)
                .find(|i| *i != ni && !map.contains(&(*i as u8)))
                .expect("free slot")
        };
        match pw {
            Some(p) => {
                let (s, mut k) = make(p, role);
                k.zeroize();
                self.slots[slot] = s;
                map[idx] = slot as u8;
            }
            None => {
                self.slots[slot] = decoy();
                map[idx] = UNSET;
            }
        }
        self.set_roles(map, &nk);
        nk.zeroize();
        Ok(())
    }

    /// Which extra passwords are set: hide, delete, account (needs the
    /// normal password).
    pub fn extras(&mut self, normal: &str) -> Result<[bool; 3]> {
        let Some((Role::Normal, _, mut nk)) = self.open(normal) else {
            bail!("wrong password")
        };
        let m = self.roles(&nk);
        nk.zeroize();
        Ok([m[0] < UNSET, m[1] < UNSET, m[2] < UNSET])
    }

    pub fn change_normal(&mut self, old: &str, new: &str) -> Result<()> {
        if !password_ok(new) {
            bail!("password rule");
        }
        let Some((Role::Normal, ni, mut ok)) = self.open(old) else {
            bail!("wrong password")
        };
        if self.clone().unlock(new).is_some_and(|r| r != Role::Normal) {
            bail!("password already used");
        }
        let map = self.roles(&ok);
        ok.zeroize();
        let (s, mut k) = make(new, Role::Normal);
        self.slots[ni] = s;
        self.set_roles(map, &k);
        k.zeroize();
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn three_passwords() {
        assert!(LockFile::new("short1").is_err());
        assert!(LockFile::new("lettersonly").is_err());
        let mut f = LockFile::new("normal-pass1").unwrap();
        let empty = f.to_json();
        assert_eq!(f.unlock("normal-pass1"), Some(Role::Normal));
        assert_eq!(f.unlock("wrong-pass1"), None);
        assert_eq!(f.fails, 1);
        f.set_extra("normal-pass1", Role::Hide, Some("hide-pass22"))
            .unwrap();
        f.set_extra("normal-pass1", Role::Delete, Some("delete-pass3"))
            .unwrap();
        assert!(
            f.set_extra("normal-pass1", Role::Delete, Some("hide-pass22"))
                .is_err()
        );
        assert_eq!(f.fails, 0);
        // Wrong-try limit.
        let mut g = LockFile::from_json(&f.to_json()).unwrap();
        assert_eq!(g.wipe_after, 10);
        assert!(g.set_wipe_after("normal-pass1", 7).is_err());
        g.set_wipe_after("normal-pass1", 5).unwrap();
        for i in 0..5 {
            assert!(!g.take_wipe(), "try {i}");
            assert_eq!(g.unlock("nope-12345"), None);
        }
        assert!(g.take_wipe());
        assert!(!g.take_wipe());
        assert_eq!(g.fails, 0);
        // Round trip through JSON; same shape as with one password.
        let mut g = LockFile::from_json(&f.to_json()).unwrap();
        assert_eq!(empty.len(), g.to_json().len());
        assert_eq!(g.unlock("hide-pass22"), Some(Role::Hide));
        assert_eq!(g.unlock("delete-pass3"), Some(Role::Delete));
        assert_eq!(g.unlock("normal-pass1"), Some(Role::Normal));
        assert_eq!(g.extras("normal-pass1").unwrap(), [true, true, false]);
        g.change_normal("normal-pass1", "normal-pass9").unwrap();
        assert_eq!(g.unlock("normal-pass1"), None);
        assert_eq!(g.unlock("normal-pass9"), Some(Role::Normal));
        assert_eq!(g.unlock("hide-pass22"), Some(Role::Hide));
        g.set_extra("normal-pass9", Role::Hide, None).unwrap();
        assert_eq!(g.unlock("hide-pass22"), None);
        assert_eq!(g.extras("normal-pass9").unwrap(), [false, true, false]);
        assert_eq!(g.unlock("delete-pass3"), Some(Role::Delete));
        // Fourth: the account password, alongside the other three.
        g.set_extra("normal-pass9", Role::Hide, Some("hide-pass22")).unwrap();
        g.set_extra("normal-pass9", Role::Account, Some("account-pass4")).unwrap();
        assert_eq!(g.extras("normal-pass9").unwrap(), [true, true, true]);
        let mut h = LockFile::from_json(&g.to_json()).unwrap();
        assert_eq!(empty.len(), h.to_json().len());
        assert_eq!(h.unlock("account-pass4"), Some(Role::Account));
        assert_eq!(h.unlock("hide-pass22"), Some(Role::Hide));
        assert_eq!(h.unlock("delete-pass3"), Some(Role::Delete));
        assert_eq!(h.unlock("normal-pass9"), Some(Role::Normal));
    }

    #[test]
    fn older_three_slot_file_still_opens() {
        // Built the way files were before the account password.
        let salt = random::<16>();
        let k = derive("normal-pass1", &salt);
        let normal = Slot { salt: hex(&salt), check: hex(&k[..32]), role: [Role::Normal as u8 ^ k[32]] };
        let old = serde_json::json!({
            "slots": [decoy(), normal, decoy()],
            "map": hex(&[3 ^ k[33], 3 ^ k[34]]),
            "fails": 0,
        });
        let mut f = LockFile::from_json(&old.to_string()).unwrap();
        assert_eq!(f.unlock("normal-pass1"), Some(Role::Normal));
        assert_eq!(f.extras("normal-pass1").unwrap(), [false, false, false]);
        f.set_extra("normal-pass1", Role::Account, Some("account-pass4")).unwrap();
        f.set_extra("normal-pass1", Role::Hide, Some("hide-pass22")).unwrap();
        assert_eq!(f.extras("normal-pass1").unwrap(), [true, false, true]);
        assert_eq!(f.unlock("account-pass4"), Some(Role::Account));
        assert_eq!(f.unlock("hide-pass22"), Some(Role::Hide));
        assert_eq!(f.unlock("normal-pass1"), Some(Role::Normal));
    }
}
