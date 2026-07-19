use std::{env, net::SocketAddr};

#[derive(Debug, Clone)]
pub struct Config {
    pub host: String,
    pub port: u16,
    pub database_url: String,
}

impl Config {
    pub fn from_env() -> anyhow::Result<Self> {
        let host = env::var("IDENTITY_HOST").unwrap_or_else(|_| "0.0.0.0".to_owned());
        let port = env::var("IDENTITY_PORT")
            .unwrap_or_else(|_| "8082".to_owned())
            .parse::<u16>()?;
        let database_url = env::var("DATABASE_URL")?;

        Ok(Self {
            host,
            port,
            database_url,
        })
    }

    pub fn socket_addr(&self) -> anyhow::Result<SocketAddr> {
        Ok(format!("{}:{}", self.host, self.port).parse()?)
    }
}
