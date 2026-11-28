// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Makes a public channel with its web page on and a few posts (one with a
//! photo), for trying the link page service. Prints the address.
//! Usage: links_seed <hs> <token> <photo.png>
#![recursion_limit = "256"]
use anyhow::Result;
use burumy_engine::Engine;

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args().nth(1).unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let photo = std::fs::read(std::env::args().nth(3).unwrap_or_default()).ok();
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-seed-{run}"));
    let a = Engine::open(&hs, &dir.join("a"), "s").await?;
    a.register(&format!("seed{run}"), "Secret-pass-123", token.as_deref()).await?;
    a.sync_once().await?;
    let ch = a.create_group("서울 러너스", &[], true).await?;
    a.set_room_about(&ch, "주말마다 한강을 같이 달려요. 처음 오셔도 괜찮아요.").await?;
    a.sync_once().await?;
    let addr = format!("seoul_runners{}", run % 1000);
    a.set_public_link(&ch, &addr).await?;
    a.sync_once().await?;
    a.set_web_page(&ch, true).await?;
    a.sync_once().await?;
    a.send_text(&ch, "이번 주 토요일 아침 7시, 여의도 한강공원 물빛광장에서 만나요.\n코스는 5km, 천천히 달려요.").await?;
    if let Some(p) = photo {
        a.send_file_with(&ch, "run.png", "image/png", p, "지난주 단체 사진이에요").await?;
    }
    a.send_text(&ch, "신청은 필요 없어요. 물은 각자 챙겨 와 주세요. 코스 지도 https://map.example.kr/run").await?;
    a.sync_once().await?;
    println!("ADDRESS {addr}");
    Ok(())
}
