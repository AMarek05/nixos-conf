use std::net::SocketAddr;
use std::time::Duration;

use axum::{
    Json, Router,
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Response},
    routing::post,
};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use tokio::net::TcpListener;
use tower_http::cors::{Any, CorsLayer};

const MINI_API_KEY_ENV: &str = "MINIMAX_API_KEY";
const MINI_URL_ENV: &str = "MINIMAX_IMAGE_URL";
const DEFAULT_MINI_URL: &str = "https://api.minimax.io/v1/image_generation";
const DEFAULT_MODEL: &str = "image-01";
const MAX_PROMPT_LEN: usize = 1500;
const MAX_N: u32 = 9;

#[derive(Clone)]
struct AppState {
    client: reqwest::Client,
    upstream_url: String,
    api_key: String,
}

#[derive(Deserialize, Serialize, Default)]
struct SillyRequest {
    #[serde(default)]
    prompt: String,
    #[serde(default)]
    model: Option<String>,
    #[serde(default)]
    n: Option<u32>,
    #[serde(default)]
    size: Option<String>,
    #[serde(default)]
    response_format: Option<String>,
}

#[derive(Serialize)]
struct ProxyError {
    error: ProxyErrorBody,
}

#[derive(Serialize)]
struct ProxyErrorBody {
    message: String,
    #[serde(rename = "type")]
    kind: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    code: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    param: Option<String>,
}

impl ProxyError {
    fn new(kind: &str, message: impl Into<String>) -> Self {
        Self {
            error: ProxyErrorBody {
                kind: kind.into(),
                message: message.into(),
                code: None,
                param: None,
            },
        }
    }

    fn with_code(mut self, code: impl Into<String>) -> Self {
        self.error.code = Some(code.into());
        self
    }

    fn with_param(mut self, param: impl Into<String>) -> Self {
        self.error.param = Some(param.into());
        self
    }
}

fn parse_size(s: &str) -> Result<(u32, u32), ProxyError> {
    let (w, h) = s.split_once('x').ok_or_else(|| {
        ProxyError::new(
            "invalid_request_error",
            format!("size {s:?} is not WxH"),
        )
    })?;
    let w: u32 = w
        .parse()
        .map_err(|_| ProxyError::new("invalid_request_error", format!("bad width {w}")))?;
    let h: u32 = h
        .parse()
        .map_err(|_| ProxyError::new("invalid_request_error", format!("bad height {h}")))?;
    if !(512..=2048).contains(&w) || !(512..=2048).contains(&h) {
        return Err(ProxyError::new(
            "invalid_request_error",
            "width and height must be in 512..=2048",
        ));
    }
    if w % 8 != 0 || h % 8 != 0 {
        return Err(ProxyError::new(
            "invalid_request_error",
            "width and height must be divisible by 8",
        ));
    }
    Ok((w, h))
}

fn aspect_ratio_preset(w: u32, h: u32) -> Option<&'static str> {
    let label = match (w, h) {
        (1024, 1024) => "1:1",
        (1280, 720) => "16:9",
        (1152, 864) => "4:3",
        (1248, 832) => "3:2",
        (832, 1248) => "2:3",
        (864, 1152) => "3:4",
        (720, 1280) => "9:16",
        (1344, 576) => "21:9",
        _ => return None,
    };
    Some(label)
}

fn translate(req: SillyRequest) -> Result<(Value, Option<bool>), ProxyError> {
    let prompt = req.prompt.trim().to_string();
    if prompt.is_empty() {
        return Err(ProxyError::new(
            "invalid_request_error",
            "prompt is required",
        ));
    }
    if prompt.chars().count() > MAX_PROMPT_LEN {
        return Err(ProxyError::new(
            "invalid_request_error",
            format!("prompt exceeds {MAX_PROMPT_LEN} chars"),
        ));
    }

    let n = req.n.unwrap_or(1).clamp(1, MAX_N);
    let client_wants_url: Option<bool> = match req.response_format.as_deref() {
        Some("url") => Some(true),
        Some("b64_json") => Some(false),
        Some(other) => {
            return Err(ProxyError::new(
                "invalid_request_error",
                format!("response_format {other:?} must be \"url\" or \"b64_json\""),
            ));
        }
        None => None,
    };

    let mut body = json!({
        "model": DEFAULT_MODEL,
        "prompt": prompt,
        "n": n,
    });

    if let Some(want_url) = client_wants_url {
        body["response_format"] = json!(if want_url { "url" } else { "base64" });
    }

    if let Some(s) = req.size.as_deref() {
        let (w, h) = parse_size(s)?;
        match aspect_ratio_preset(w, h) {
            Some(label) => {
                body["aspect_ratio"] = json!(label);
            }
            None => {
                body["width"] = json!(w);
                body["height"] = json!(h);
            }
        }
    }

    Ok((body, client_wants_url))
}

fn upstream_status_message(v: &Value) -> Option<String> {
    v.get("base_resp")
        .and_then(|b| b.get("status_msg"))
        .and_then(|s| s.as_str())
        .map(String::from)
}

fn upstream_status_code(v: &Value) -> Option<i64> {
    v.get("base_resp")
        .and_then(|b| b.get("status_code"))
        .and_then(|c| c.as_i64())
}

fn map_minimax_error(status_code: i64, status_msg: Option<String>) -> (StatusCode, ProxyError) {
    let msg = status_msg.unwrap_or_else(|| format!("upstream returned status {status_code}"));
    let code_str = status_code.to_string();
    match status_code {
        1002 => (
            StatusCode::TOO_MANY_REQUESTS,
            ProxyError::new("rate_limit_error", msg).with_code(code_str),
        ),
        1004 => (
            StatusCode::UNAUTHORIZED,
            ProxyError::new("invalid_request_error", msg)
                .with_code(code_str)
                .with_param("Authorization"),
        ),
        1008 => (
            StatusCode::PAYMENT_REQUIRED,
            ProxyError::new("billing_error", msg).with_code(code_str),
        ),
        1026 => (
            StatusCode::BAD_REQUEST,
            ProxyError::new("invalid_request_error", msg)
                .with_code(code_str)
                .with_param("prompt"),
        ),
        2013 => (
            StatusCode::BAD_REQUEST,
            ProxyError::new("invalid_request_error", msg).with_code(code_str),
        ),
        _ => (
            StatusCode::BAD_GATEWAY,
            ProxyError::new("upstream_error", msg).with_code(code_str),
        ),
    }
}

fn image_arrays(v: &Value) -> Option<(Vec<String>, Vec<String>)> {
    let data = v.get("data")?;
    let urls: Vec<String> = data
        .get("image_urls")
        .and_then(|u| u.as_array())
        .map(|a| a.iter().filter_map(|x| x.as_str().map(String::from)).collect())
        .unwrap_or_default();
    let b64s: Vec<String> = data
        .get("image_base64")
        .and_then(|b| b.as_array())
        .map(|a| a.iter().filter_map(|x| x.as_str().map(String::from)).collect())
        .unwrap_or_default();
    Some((urls, b64s))
}

fn build_openai_response(
    upstream: Value,
    client_wants_url: Option<bool>,
    upstream_http_status: u16,
) -> (StatusCode, Value) {
    let upstream_http_status_code =
        StatusCode::from_u16(upstream_http_status).unwrap_or(StatusCode::BAD_GATEWAY);

    if let Some(code) = upstream_status_code(&upstream) {
        if code != 0 {
            let (status, err) = map_minimax_error(code, upstream_status_message(&upstream));
            return (status, serde_json::to_value(err).unwrap());
        }
    } else if !upstream_http_status_code.is_success() {
        let msg =
            upstream_status_message(&upstream).unwrap_or_else(|| "upstream request failed".into());
        let err = ProxyError::new("upstream_error", msg);
        return (upstream_http_status_code, serde_json::to_value(err).unwrap());
    }

    let (urls, b64s) = match image_arrays(&upstream) {
        Some(arrays) => arrays,
        None => {
            let err = ProxyError::new(
                "upstream_error",
                "upstream response missing data.image_urls / data.image_base64",
            );
            return (StatusCode::BAD_GATEWAY, serde_json::to_value(err).unwrap());
        }
    };

    let upstream_format = if !b64s.is_empty() {
        Some("base64")
    } else if !urls.is_empty() {
        Some("url")
    } else {
        None
    };

    let emit_url = match (client_wants_url, upstream_format) {
        (Some(true), _) => true,
        (Some(false), _) => false,
        (None, Some("url")) => true,
        (None, Some("base64")) => false,
        (_, _) => {
            let err = ProxyError::new("upstream_error", "upstream returned empty image arrays");
            return (StatusCode::BAD_GATEWAY, serde_json::to_value(err).unwrap());
        }
    };

    let items_data: &[String] = if emit_url { &urls } else { &b64s };

    let failed_count = upstream
        .get("metadata")
        .and_then(|m| m.get("failed_count"))
        .and_then(|c| c.as_i64())
        .unwrap_or(0);
    if failed_count > 0 {
        let err = ProxyError::new(
            "upstream_error",
            format!("upstream reported {failed_count} failed images"),
        );
        return (StatusCode::BAD_GATEWAY, serde_json::to_value(err).unwrap());
    }

    let id = upstream
        .get("id")
        .and_then(|i| i.as_str())
        .map(String::from);
    let created = now_epoch();

    let mut items: Vec<Value> = items_data
        .iter()
        .map(|s| {
            if emit_url {
                json!({ "url": s })
            } else {
                json!({ "b64_json": s })
            }
        })
        .collect();
    if emit_url {
        for item in &mut items {
            item["revised_prompt"] = Value::Null;
        }
    }

    let mut body = json!({
        "created": created,
        "data": items,
    });
    if let Some(i) = id {
        body["id"] = json!(i);
    }

    (StatusCode::OK, body)
}

fn now_epoch() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0)
}

async fn handle(State(state): State<AppState>, Json(req): Json<SillyRequest>) -> Response {
    let (translated, client_wants_url) = match translate(req) {
        Ok(v) => v,
        Err(e) => return (StatusCode::BAD_REQUEST, Json(e)).into_response(),
    };

    let upstream_resp = match state
        .client
        .post(&state.upstream_url)
        .bearer_auth(&state.api_key)
        .json(&translated)
        .send()
        .await
    {
        Ok(r) => r,
        Err(e) => {
            return (
                StatusCode::BAD_GATEWAY,
                Json(ProxyError::new(
                    "upstream_error",
                    format!("upstream request failed: {e}"),
                )),
            )
                .into_response();
        }
    };

    let upstream_http_status = upstream_resp.status().as_u16();
    let bytes = upstream_resp
        .bytes()
        .await
        .unwrap_or_else(|_| b"{}".to_vec().into());

    let parsed: Value = serde_json::from_slice(&bytes).unwrap_or(Value::Null);

    let (status, body) = build_openai_response(parsed, client_wants_url, upstream_http_status);

    (status, Json(body)).into_response()
}

#[tokio::main]
async fn main() {
    let api_key = match std::env::var(MINI_API_KEY_ENV) {
        Ok(v) if !v.is_empty() => v,
        _ => {
            eprintln!("fatal: {MINI_API_KEY_ENV} not set or empty");
            std::process::exit(2);
        }
    };
    let upstream_url = std::env::var(MINI_URL_ENV).unwrap_or_else(|_| DEFAULT_MINI_URL.to_string());

    let port: u16 = std::env::var("IMAGE_PROXY_PORT")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(8765);
    let bind: std::net::IpAddr = std::env::var("IMAGE_PROXY_BIND")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or_else(|| "127.0.0.1".parse().unwrap());

    let client = reqwest::Client::builder()
        .timeout(Duration::from_secs(120))
        .build()
        .expect("build http client");

    let state = AppState {
        client,
        upstream_url,
        api_key,
    };

    let app = Router::new()
        .route("/v1/images/generations", post(handle))
        .layer(
            CorsLayer::new()
                .allow_origin(Any)
                .allow_methods(Any)
                .allow_headers(Any),
        )
        .with_state(state);

    let addr = SocketAddr::from((bind, port));
    let listener = TcpListener::bind(&addr)
        .await
        .unwrap_or_else(|e| panic!("bind {addr}: {e}"));

    eprintln!("image-proxy listening on http://{addr}");
    axum::serve(listener, app).await.expect("serve");
}
