// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Business accounts: space reserved, switched off (Eric, 2026-11-23).
//!
//! Plan: a company (org) owns its members' accounts; an org admin manages
//! seats from an admin console. The server sets `im.securemessenger.org`
//! account data on member accounts. Before switching this on, our server
//! fork must refuse users writing that type themselves.

use anyhow::Result;
use matrix_sdk::ruma::events::GlobalAccountDataEventType;
use serde::{Deserialize, Serialize};

use crate::{Engine, to_err};

pub const ORG_EVENT: &str = "im.securemessenger.org";

/// Off until business accounts launch.
pub const BUSINESS_ENABLED: bool = false;

#[derive(Clone, Debug, Default, Serialize, Deserialize, PartialEq)]
pub struct Org {
    pub org_id: String,
    pub name: String,
    /// "member" or "admin".
    pub role: String,
}

impl Engine {
    /// The company this account belongs to (always None while switched off).
    pub async fn org(&self) -> Result<Option<Org>> {
        if !BUSINESS_ENABLED {
            return Ok(None);
        }
        let raw = self
            .client
            .account()
            .account_data_raw(GlobalAccountDataEventType::from(ORG_EVENT))
            .await
            .map_err(to_err)?;
        Ok(raw.and_then(|r| serde_json::from_str::<Org>(r.json().get()).ok()))
    }
}
