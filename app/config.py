from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Reads from environment variables. Names match the Secret keys used in the
    reference scenario (DATABASE_HOST/USER/PASSWORD/NAME), so the same K8s
    Secret shape works unmodified once this is deployed.
    """

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_host: str = "localhost"
    database_port: int = 5432
    database_user: str = "postgres"
    database_password: str = "postgres"
    database_name: str = "booking"

    @property
    def database_url(self) -> str:
        return (
            f"postgresql+psycopg2://{self.database_user}:{self.database_password}"
            f"@{self.database_host}:{self.database_port}/{self.database_name}"
        )


settings = Settings()
