// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Checking another person ("보안 코드 확인" / 암호화 page): both phones show
//! the same 7 emoji; when both people say they match, each phone marks the
//! other person's keys as trusted. Requests travel inside the encrypted 1:1
//! chat. Nothing here is visible to the server.

use anyhow::{Context, Result};
use matrix_sdk::ruma::UserId;

use crate::{Engine, to_err};

/// One of a person's devices with its key fingerprint (advanced view).
#[derive(Clone, Debug)]
pub struct PeerDevice {
    pub device_id: String,
    pub name: String,
    /// ed25519 key, base64 (shown in groups of four).
    pub key: String,
    pub verified: bool,
}

impl Engine {
    /// Where a check stands: "incoming" (asked, not accepted yet),
    /// "waiting" (I asked, the other phone has not accepted), "starting",
    /// "emoji" (compare now), "confirmed" (I said they match; waiting for
    /// the other side), "done", "cancelled" or "gone".
    pub async fn verify_state(&self, other: &UserId, flow_id: &str) -> Result<String> {
        let enc = self.client.encryption();
        if let Some(v) = enc.get_verification(other, flow_id).await {
            if let Some(sas) = v.sas() {
                if sas.is_done() {
                    return Ok("done".into());
                }
                if sas.is_cancelled() {
                    return Ok("cancelled".into());
                }
                if !sas.we_started() && !sas.can_be_presented() {
                    let _ = sas.accept().await;
                }
                if matches!(
                    sas.state(),
                    matrix_sdk::encryption::verification::SasState::Confirmed
                ) {
                    return Ok("confirmed".into());
                }
                if sas.can_be_presented() {
                    return Ok("emoji".into());
                }
                return Ok("starting".into());
            }
        }
        let Some(req) = enc.get_verification_request(other, flow_id).await else {
            // A finished check is dropped from memory; if the person is
            // trusted now, it ended well.
            if self.is_user_verified(other).await.unwrap_or(false) {
                return Ok("done".into());
            }
            return Ok("gone".into());
        };
        if req.is_done() {
            return Ok("done".into());
        }
        if req.is_cancelled() {
            return Ok("cancelled".into());
        }
        if req.is_ready() {
            // The one who asked starts the emoji step.
            if req.we_started() {
                let _ = req.start_sas().await;
            }
            return Ok("starting".into());
        }
        Ok(if req.we_started() {
            "waiting"
        } else {
            "incoming"
        }
        .into())
    }

    /// "They don't match" or "stop": ends the check on both phones.
    pub async fn cancel_verification(&self, other: &UserId, flow_id: &str) -> Result<()> {
        let enc = self.client.encryption();
        if let Some(v) = enc.get_verification(other, flow_id).await {
            if let Some(sas) = v.sas() {
                sas.mismatch().await.map_err(to_err)?;
                return Ok(());
            }
        }
        let req = enc
            .get_verification_request(other, flow_id)
            .await
            .context("no such check")?;
        req.cancel().await.map_err(to_err)?;
        Ok(())
    }

    /// A person's devices with their key fingerprints.
    pub async fn peer_devices(&self, other: &UserId) -> Result<Vec<PeerDevice>> {
        let list = self
            .client
            .encryption()
            .get_user_devices(other)
            .await
            .map_err(to_err)?;
        Ok(list
            .devices()
            .map(|d| PeerDevice {
                device_id: d.device_id().to_string(),
                name: d.display_name().unwrap_or_default().to_owned(),
                key: d.ed25519_key().map(|k| k.to_base64()).unwrap_or_default(),
                verified: d.is_verified(),
            })
            .collect())
    }
}

impl Engine {
    /// "메시지 신고": tells our server's operators about a message. Messages
    /// are encrypted, so the words the person chose to report travel with
    /// the report (the sheet says the operator will read them).
    pub async fn report_message(
        &self,
        room_id: &matrix_sdk::ruma::RoomId,
        event_id: &str,
        reason: &str,
        shown: &str,
    ) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let id = matrix_sdk::ruma::OwnedEventId::try_from(event_id).map_err(to_err)?;
        let shown: String = shown.chars().take(2000).collect();
        let text = if shown.is_empty() {
            reason.to_owned()
        } else {
            format!("{reason}\n---\n{shown}")
        };
        room.report_content(id, Some(text)).await.map_err(to_err)?;
        Ok(())
    }
}
