// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Link previews, made on the SENDER's phone only (like Signal): the
//! sender's phone reads the page title and picture, encrypts them into the
//! message, and the people who receive it never contact that website.
//! Nothing about the link goes to our server in readable form.

use std::time::Duration;

use anyhow::{Context, Result, bail};

/// Field inside an encrypted text message.
pub const PREVIEW_FIELD: &str = "im.securemessenger.preview";

const MAX_PAGE: usize = 512 * 1024;
const MAX_IMAGE: usize = 2 * 1024 * 1024;

#[derive(Debug, Clone, PartialEq, Default)]
pub struct Page {
    pub url: String,
    pub title: String,
    pub description: Option<String>,
    pub site: Option<String>,
    pub image_url: Option<String>,
}

/// The first web link in a text, if any.
pub fn first_link(text: &str) -> Option<String> {
    all_links(text).into_iter().next()
}

/// Every web link in a text, in order, without repeats (tip 400: the sender
/// can pick which one gets the card).
pub fn all_links(text: &str) -> Vec<String> {
    let mut out: Vec<String> = Vec::new();
    for w in text.split_whitespace() {
        // "[words](https://…)" marks: the address inside the brackets.
        let w = w.rsplit("](").next().unwrap_or(w);
        let w = w
            .trim_end_matches(|c: char| ".,!?)]}>\"'".contains(c))
            .trim_start_matches(|c: char| "(<[\"'".contains(c));
        if (w.starts_with("https://") || w.starts_with("http://")) && w.len() > 10 && w[8..].contains('.') && !out.iter().any(|x| x == w) {
            out.push(w.to_owned());
        }
    }
    out
}

fn client() -> Result<reqwest::Client> {
    Ok(reqwest::Client::builder()
        .timeout(Duration::from_secs(5))
        .redirect(reqwest::redirect::Policy::limited(4))
        // A plain browser-like name: nothing about the user or the app.
        .user_agent("Mozilla/5.0 (compatible; LinkPreview)")
        .build()?)
}

async fn read_limited(mut resp: reqwest::Response, max: usize) -> Result<Vec<u8>> {
    let mut out = Vec::new();
    while let Some(chunk) = resp.chunk().await? {
        out.extend_from_slice(&chunk);
        if out.len() > max {
            out.truncate(max);
            break;
        }
    }
    Ok(out)
}

/// Reads the page and picks out its title, summary and picture.
pub async fn fetch_page(url: &str) -> Result<Page> {
    let resp = client()?.get(url).send().await?.error_for_status()?;
    let final_url = resp.url().to_string();
    let html_ok = resp
        .headers()
        .get(reqwest::header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .is_some_and(|v| v.contains("html"));
    if !html_ok {
        bail!("not a web page");
    }
    let body = read_limited(resp, MAX_PAGE).await?;
    let html = String::from_utf8_lossy(&body);
    let mut page = parse(&html);
    if page.title.is_empty() {
        bail!("no title");
    }
    page.image_url = page.image_url.and_then(|i| absolute(&final_url, &i));
    page.url = url.to_owned();
    Ok(page)
}

/// Downloads the page picture (images only, at most 2 MB).
pub async fn fetch_image(url: &str) -> Result<(String, Vec<u8>)> {
    let resp = client()?.get(url).send().await?.error_for_status()?;
    let mime = resp
        .headers()
        .get(reqwest::header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .unwrap_or_default()
        .split(';')
        .next()
        .unwrap_or_default()
        .trim()
        .to_owned();
    if !mime.starts_with("image/") || mime == "image/svg+xml" {
        bail!("not a picture");
    }
    let data = read_limited(resp, MAX_IMAGE + 1).await?;
    if data.len() > MAX_IMAGE {
        bail!("picture too big");
    }
    Ok((mime, data))
}

fn absolute(base: &str, link: &str) -> Option<String> {
    if link.starts_with("https://") || link.starts_with("http://") {
        return Some(link.to_owned());
    }
    let scheme_end = base.find("://")? + 3;
    if let Some(rest) = link.strip_prefix("//") {
        return Some(format!("{}{rest}", &base[..scheme_end]));
    }
    let host_end = base[scheme_end..]
        .find('/')
        .map(|i| i + scheme_end)
        .unwrap_or(base.len());
    if link.starts_with('/') {
        return Some(format!("{}{link}", &base[..host_end]));
    }
    let dir_end = base.rfind('/').filter(|i| *i >= host_end).map(|i| i + 1);
    match dir_end {
        Some(d) => Some(format!("{}{link}", &base[..d])),
        None => Some(format!("{}/{link}", &base[..host_end])),
    }
}

fn unescape(s: &str) -> String {
    s.replace("&amp;", "&")
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&quot;", "\"")
        .replace("&#39;", "'")
        .replace("&#x27;", "'")
        .replace("&nbsp;", " ")
        .split_whitespace()
        .collect::<Vec<_>>()
        .join(" ")
}

/// Value of one attribute inside a tag like `<meta property="og:title" content="...">`.
fn attr(tag: &str, name: &str) -> Option<String> {
    let lower = tag.to_ascii_lowercase();
    let mut from = 0;
    while let Some(i) = lower[from..].find(name) {
        let at = from + i;
        from = at + name.len();
        let before_ok = at == 0 || lower.as_bytes()[at - 1].is_ascii_whitespace();
        let rest = lower[from..].trim_start();
        if !before_ok || !rest.starts_with('=') {
            continue;
        }
        let start = tag.len() - rest.len() + 1;
        let v = tag[start..].trim_start();
        let q = v.chars().next()?;
        return if q == '"' || q == '\'' {
            v[1..].find(q).map(|e| v[1..1 + e].to_owned())
        } else {
            Some(
                v.split(|c: char| c.is_whitespace() || c == '>')
                    .next()?
                    .to_owned(),
            )
        };
    }
    None
}

fn clip(s: String, n: usize) -> String {
    if s.chars().count() <= n {
        s
    } else {
        format!("{}…", s.chars().take(n).collect::<String>().trim_end())
    }
}

pub fn parse(html: &str) -> Page {
    let head_end = html
        .to_ascii_lowercase()
        .find("</head>")
        .unwrap_or(html.len());
    let head = &html[..head_end];
    let mut page = Page::default();
    let (mut og_title, mut desc, mut og_desc, mut image, mut site) = (None, None, None, None, None);
    for piece in head.split('<').skip(1) {
        let tag = piece.split('>').next().unwrap_or_default();
        if !tag.to_ascii_lowercase().starts_with("meta") {
            continue;
        }
        let key = attr(tag, "property")
            .or_else(|| attr(tag, "name"))
            .unwrap_or_default()
            .to_ascii_lowercase();
        let Some(content) = attr(tag, "content") else {
            continue;
        };
        let content = unescape(&content);
        if content.is_empty() {
            continue;
        }
        match key.as_str() {
            "og:title" | "twitter:title" => {
                og_title.get_or_insert(content);
            }
            "og:description" | "twitter:description" => {
                og_desc.get_or_insert(content);
            }
            "description" => {
                desc.get_or_insert(content);
            }
            "og:image" | "og:image:url" | "og:image:secure_url" | "twitter:image" => {
                image.get_or_insert(content);
            }
            "og:site_name" => {
                site.get_or_insert(content);
            }
            _ => {}
        }
    }
    let title_tag = {
        let lower = head.to_ascii_lowercase();
        lower.find("<title").and_then(|s| {
            let open_end = s + lower[s..].find('>')? + 1;
            let close = open_end + lower[open_end..].find("</title")?;
            Some(unescape(&head[open_end..close]))
        })
    };
    page.title = clip(og_title.or(title_tag).unwrap_or_default(), 120);
    page.description = og_desc.or(desc).map(|d| clip(d, 240));
    page.image_url = image;
    page.site = site.map(|s| clip(s, 60));
    page
}

/// Short host name shown under the title ("example.com").
pub fn host(url: &str) -> String {
    let rest = url.split("://").nth(1).unwrap_or(url);
    rest.split(['/', '?', '#'])
        .next()
        .unwrap_or_default()
        .trim_start_matches("www.")
        .to_owned()
}

/// Ensures the picture URL is a web address before fetching.
pub fn check_web(url: &str) -> Result<()> {
    let ok = url.starts_with("https://") || url.starts_with("http://");
    ok.then_some(()).context("not a web address")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn finds_link() {
        assert_eq!(
            first_link("봐요 https://example.com/a?b=1."),
            Some("https://example.com/a?b=1".into())
        );
        assert_eq!(
            first_link("(https://x.co/y)"),
            Some("https://x.co/y".into())
        );
        assert_eq!(first_link("no link here"), None);
        assert_eq!(first_link("ftp://example.com"), None);
    }

    #[test]
    fn lists_every_link_once() {
        let t = "목록 https://a.com/x 그리고 [커피](https://b.org/c). 또 https://a.com/x 와 (t:123)";
        assert_eq!(all_links(t), vec!["https://a.com/x".to_string(), "https://b.org/c".to_string()]);
        assert!(all_links("링크 없음 [내일](t:1772272800)").is_empty());
    }

    #[test]
    fn reads_meta() {
        let html = r#"<html><head><title>Plain &amp; title</title>
            <meta property="og:title" content="Big &quot;news&quot;">
            <meta name='description' content='Short summary'>
            <META PROPERTY="og:image" CONTENT="/img/a.png">
            <meta property="og:site_name" content="Example"></head><body><meta property="og:title" content="no"></body>"#;
        let p = parse(html);
        assert_eq!(p.title, "Big \"news\"");
        assert_eq!(p.description.as_deref(), Some("Short summary"));
        assert_eq!(p.image_url.as_deref(), Some("/img/a.png"));
        assert_eq!(p.site.as_deref(), Some("Example"));
        assert_eq!(
            parse("<head><title> Only  title </title></head>").title,
            "Only title"
        );
    }

    #[test]
    fn makes_absolute() {
        assert_eq!(
            absolute("https://a.com/x/y.html", "/i.png").unwrap(),
            "https://a.com/i.png"
        );
        assert_eq!(
            absolute("https://a.com/x/y.html", "i.png").unwrap(),
            "https://a.com/x/i.png"
        );
        assert_eq!(
            absolute("https://a.com", "i.png").unwrap(),
            "https://a.com/i.png"
        );
        assert_eq!(
            absolute("https://a.com/x", "//cdn.b.com/i.png").unwrap(),
            "https://cdn.b.com/i.png"
        );
        assert_eq!(host("https://www.example.com/a/b"), "example.com");
    }
}
