import json
from functools import lru_cache
from typing import Optional

import boto3
from pydantic_settings import BaseSettings, SettingsConfigDict


@lru_cache(maxsize=None)
def _fetch_secret_credentials(secret_arn: str, region: str) -> "tuple[str, str]":
    """
    Reads an RDS-managed Secrets Manager secret, which contains only
    {"username": ..., "password": ...} (verified against the RDS User Guide
    -- host/port/dbname are NOT in this secret, unlike a manually-created
    one). Cached per-process since this is a network call we only want to
    make once, not on every request.
    """
    client = boto3.client("secretsmanager", region_name=region)
    secret = json.loads(client.get_secret_value(SecretId=secret_arn)["SecretString"])
    return secret["username"], secret["password"]


class Settings(BaseSettings):
    """
    Host/port/name are plain (non-secret) config. Credentials come from one
    of two places:
      - DATABASE_SECRET_ARN set (real deployments): username/password
        fetched from AWS Secrets Manager via IRSA -- see terraform/main.tf
        for the role/policy this depends on.
      - DATABASE_SECRET_ARN unset (local dev, tests): DATABASE_USER/
        DATABASE_PASSWORD env vars / .env, as before this existed.
    """

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_host: str = "localhost"
    database_port: int = 5432
    database_name: str = "booking"
    database_user: str = "postgres"
    database_password: str = "postgres"
    database_secret_arn: Optional[str] = None
    aws_region: str = "us-east-1"

    @property
    def database_url(self) -> str:
        if self.database_secret_arn:
            user, password = _fetch_secret_credentials(self.database_secret_arn, self.aws_region)
        else:
            user, password = self.database_user, self.database_password

        return (
            f"postgresql+psycopg2://{user}:{password}"
            f"@{self.database_host}:{self.database_port}/{self.database_name}"
        )


settings = Settings()
