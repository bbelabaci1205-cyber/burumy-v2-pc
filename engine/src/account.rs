// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Account tools for Settings: blocked people, my logged-in devices,
//! changing the password, my keys, and the "saved messages" chat.

use anyhow::{Context, Result};
use matrix_sdk::ruma::{
    OwnedDeviceId, OwnedRoomId, UserId,
    api::client::uiaa::{AuthData, MatrixUserIdentifier, Password, UserIdentifier},
    events::{GlobalAccountDataEventType, ignored_user_list::IgnoredUserListEventContent},
    serde::Raw,
};

use crate::{Engine, to_err};

/// One device logged in to my account.
#[derive(Clone, Debug)]
pub struct DeviceRow {
    pub device_id: String,
    pub name: String,
    /// Last time the server saw it (ms), 0 if unknown.
    pub last_seen: u64,
    pub this_device: bool,
    /// Checked with an emoji check or the recovery key.
    pub verified: bool,
}

const SAVED: &str = "im.burumy.saved";

impl Engine {
    fn password_auth(&self, password: &str) -> Result<AuthData> {
        let me = self.client.user_id().context("no user")?;
        Ok(AuthData::Password(Password::new(
            UserIdentifier::Matrix(MatrixUserIdentifier::new(me.to_string())),
            password.to_owned(),
        )))
    }

    /// People I blocked (their messages and invitations do not reach me).
    pub async fn blocked(&self) -> Vec<String> {
        self.client
            .account()
            .account_data::<IgnoredUserListEventContent>()
            .await
            .ok()
            .flatten()
            .and_then(|r| r.deserialize().ok())
            .map(|c| c.ignored_users.keys().map(|u| u.to_string()).collect())
            .unwrap_or_default()
    }

    pub async fn block(&self, user: &UserId, on: bool) -> Result<()> {
        let a = self.client.account();
        if on {
            a.ignore_user(user).await
        } else {
            a.unignore_user(user).await
        }
        .map_err(to_err)
    }

    /// My logged-in devices, this one first.
    pub async fn devices(&self) -> Result<Vec<DeviceRow>> {
        let me = self.client.user_id().context("no user")?.to_owned();
        let mine = self.client.device_id().map(|d| d.to_owned());
        let list = self.client.devices().await.map_err(to_err)?;
        let mut out = Vec::new();
        for d in list.devices {
            let verified = match self.client.encryption().get_device(&me, &d.device_id).await {
                Ok(Some(x)) => x.is_verified(),
                _ => false,
            };
            out.push(DeviceRow {
                this_device: Some(&d.device_id) == mine.as_ref(),
                name: d.display_name.unwrap_or_default(),
                last_seen: d.last_seen_ts.map(|t| u64::from(t.0)).unwrap_or(0),
                device_id: d.device_id.to_string(),
                verified,
            });
        }
        out.sort_by(|a, b| {
            b.this_device
                .cmp(&a.this_device)
                .then(b.last_seen.cmp(&a.last_seen))
        });
        Ok(out)
    }

    /// Logs other devices out (needs my password again).
    pub async fn log_out_devices(&self, ids: &[String], password: &str) -> Result<()> {
        let ids: Vec<OwnedDeviceId> = ids.iter().map(|s| s.as_str().into()).collect();
        self.client
            .delete_devices(&ids, Some(self.password_auth(password)?))
            .await
            .map_err(to_err)?;
        Ok(())
    }

    pub async fn change_password(&self, old: &str, new: &str) -> Result<()> {
        self.client
            .account()
            .change_password(new, Some(self.password_auth(old)?))
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// (my identity key, this device's key), for comparing by hand.
    pub async fn my_keys(&self) -> (String, String) {
        let e = self.client.encryption();
        let device = e
            .curve25519_key()
            .await
            .map(|k| k.to_base64())
            .unwrap_or_default();
        (e.ed25519_key().await.unwrap_or_default(), device)
    }

    /// Is this device checked (emoji check or recovery key)?
    pub async fn this_device_verified(&self) -> bool {
        matches!(self.client.encryption().get_own_device().await, Ok(Some(d)) if d.is_verified())
    }

    /// My "saved messages" chat (only me in it), made on first use. Its id
    /// is kept in my account so all my devices find the same one.
    pub async fn saved_room(&self, create: bool) -> Result<Option<OwnedRoomId>> {
        let kind = GlobalAccountDataEventType::from(SAVED);
        let a = self.client.account();
        let known = a
            .account_data_raw(kind.clone())
            .await
            .ok()
            .flatten()
            .and_then(|r| r.deserialize_as::<serde_json::Value>().ok())
            .and_then(|v| v.get("room_id").and_then(|x| x.as_str()).map(str::to_owned))
            .and_then(|s| OwnedRoomId::try_from(s).ok());
        if let Some(id) = known {
            if self.client.get_room(&id).is_some() {
                return Ok(Some(id));
            }
        }
        if !create {
            return Ok(None);
        }
        let id = self.create_group("", &[], false).await?;
        let content =
            Raw::from_json_string(serde_json::json!({ "room_id": id.to_string() }).to_string())?;
        a.set_account_data_raw(kind, content)
            .await
            .map_err(to_err)?;
        Ok(Some(id))
    }
}
