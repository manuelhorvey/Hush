use std::{env, net::SocketAddr};

#[derive(Debug, Clone)]
pub struct Config {
    pub host: String,
    pub port: u16,
}

impl Config {
    pub fn from_env() -> anyhow::Result<Self> {
        let host = env::var("GATEWAY_HOST").unwrap_or_else(|_| "0.0.0.0".to_owned());
        let port = env::var("GATEWAY_PORT")
            .unwrap_or_else(|_| "8080".to_owned())
            .parse::<u16>()?;

        Ok(Self { host, port })
    }

    pub fn socket_addr(&self) -> anyhow::Result<SocketAddr> {
        Ok(format!("{}:{}", self.host, self.port).parse()?)
    }
}
