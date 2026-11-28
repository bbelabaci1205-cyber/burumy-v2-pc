// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Streaks for 1:1 chats, worked out on the phone only (the server never
//! learns them). A day counts when both people sent at least one message
//! that day (the phone's own calendar day). The streak is the run of such
//! days ending today, or ending yesterday while today is still open.
//!
//! 그룹 스트릭 (Snapchat 2025 has group streaks): in a group a day counts
//! when enough different members wrote that day — half the group, at least
//! 2 and at most 5 people (so big groups don't need everyone).

use std::collections::BTreeSet;

pub const DAY_MS: i64 = 24 * 60 * 60 * 1000;

/// Streaks are shown from this many days on.
pub const SHOW_FROM: u32 = 3;

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct Streak {
    pub days: u32,
    /// Today is not done yet: one more day without both writing ends it.
    pub at_risk: bool,
}

fn day(ts_ms: u64, tz_offset_min: i32) -> i64 {
    (ts_ms as i64 + tz_offset_min as i64 * 60_000).div_euclid(DAY_MS)
}

/// `msgs`: (time ms, sent by me).
pub fn streak(msgs: &[(u64, bool)], now_ms: u64, tz_offset_min: i32) -> Streak {
    let mut mine = BTreeSet::new();
    let mut theirs = BTreeSet::new();
    for (ts, me) in msgs {
        if *me {
            mine.insert(day(*ts, tz_offset_min));
        } else {
            theirs.insert(day(*ts, tz_offset_min));
        }
    }
    let both = |d: i64| mine.contains(&d) && theirs.contains(&d);
    let today = day(now_ms, tz_offset_min);
    let (mut d, at_risk) = if both(today) {
        (today, false)
    } else {
        (today - 1, true)
    };
    let mut days = 0;
    while both(d) {
        days += 1;
        d -= 1;
    }
    Streak {
        days,
        at_risk: at_risk && days > 0,
    }
}

/// People who must write on a day for a group of [members] to keep its
/// streak: half the group, at least 2, at most 5.
pub fn group_need(members: usize) -> usize {
    members.div_ceil(2).clamp(2, 5)
}

/// Group streak. `msgs`: (time ms, sender).
pub fn group_streak(msgs: &[(u64, &str)], members: usize, now_ms: u64, tz_offset_min: i32) -> Streak {
    if members < 2 {
        return Streak::default();
    }
    let need = group_need(members);
    let mut by_day: std::collections::BTreeMap<i64, BTreeSet<&str>> = Default::default();
    for (ts, who) in msgs {
        by_day.entry(day(*ts, tz_offset_min)).or_default().insert(who);
    }
    let full = |d: i64| by_day.get(&d).is_some_and(|w| w.len() >= need);
    let today = day(now_ms, tz_offset_min);
    let (mut d, at_risk) = if full(today) { (today, false) } else { (today - 1, true) };
    let mut days = 0;
    while full(d) {
        days += 1;
        d -= 1;
    }
    Streak {
        days,
        at_risk: at_risk && days > 0,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const H: u64 = 60 * 60 * 1000;
    // 2026-11-23 12:00 UTC
    const NOW: u64 = 1_795_435_200_000;

    fn at(days_ago: u64, hour: u64) -> u64 {
        (NOW / DAY_MS as u64 - days_ago) * DAY_MS as u64 + hour * H
    }

    #[test]
    fn counts_days_where_both_wrote() {
        let m = vec![
            (at(2, 9), true),
            (at(2, 10), false),
            (at(1, 9), true),
            (at(1, 22), false),
            (at(0, 8), true),
            (at(0, 9), false),
        ];
        assert_eq!(
            streak(&m, NOW, 0),
            Streak {
                days: 3,
                at_risk: false
            }
        );
        // Today only I wrote: streak of 2 (until yesterday), at risk.
        let m2: Vec<_> = m
            .iter()
            .filter(|(t, me)| !(*t >= at(0, 0) && !*me))
            .cloned()
            .collect();
        assert_eq!(
            streak(&m2, NOW, 0),
            Streak {
                days: 2,
                at_risk: true
            }
        );
        // A gap day breaks it.
        let m3 = vec![
            (at(3, 9), true),
            (at(3, 9), false),
            (at(1, 9), true),
            (at(1, 9), false),
        ];
        assert_eq!(
            streak(&m3, NOW, 0),
            Streak {
                days: 1,
                at_risk: true
            }
        );
        assert_eq!(streak(&[], NOW, 0), Streak::default());
        // One side only never counts.
        assert_eq!(
            streak(&[(at(0, 1), true), (at(1, 1), true)], NOW, 0).days,
            0
        );
    }

    #[test]
    fn uses_the_phone_calendar_day() {
        // 23:30 and 00:30 UTC are the same day in Korea (UTC+9).
        let m = vec![(at(1, 23) + H / 2, true), (at(0, 0) + H / 2, false)];
        assert_eq!(streak(&m, NOW, 0).days, 0);
        assert_eq!(streak(&m, NOW, 9 * 60).days, 1);
    }

    #[test]
    fn group_days_need_half_the_group() {
        assert_eq!(group_need(2), 2);
        assert_eq!(group_need(5), 3);
        assert_eq!(group_need(200), 5);
        let m = vec![
            (at(2, 9), "@a"),
            (at(2, 10), "@b"),
            (at(2, 11), "@c"),
            (at(1, 9), "@a"),
            (at(1, 9), "@a"),
            (at(1, 22), "@b"),
            (at(1, 23), "@d"),
            (at(0, 8), "@a"),
        ];
        // 5 members: 3 people a day. Today only @a so far: 2 days, at risk.
        assert_eq!(group_streak(&m, 5, NOW, 0), Streak { days: 2, at_risk: true });
        // One person writing twice doesn't count twice.
        let lone = vec![(at(0, 8), "@a"), (at(0, 9), "@a")];
        assert_eq!(group_streak(&lone, 2, NOW, 0), Streak::default());
    }
}
