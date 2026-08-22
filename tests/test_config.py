from unittest.mock import MagicMock, patch

from app.config import Settings, _fetch_secret_credentials


def test_database_url_uses_plain_env_vars_when_no_secret_arn():
    settings = Settings(
        database_host="db.example.com",
        database_port=5432,
        database_name="booking",
        database_user="plainuser",
        database_password="plainpass",
    )

    assert settings.database_url == (
        "postgresql+psycopg2://plainuser:plainpass@db.example.com:5432/booking"
    )


def test_database_url_fetches_credentials_from_secrets_manager_when_arn_set():
    _fetch_secret_credentials.cache_clear()

    fake_secretsmanager = MagicMock()
    fake_secretsmanager.get_secret_value.return_value = {
        "SecretString": '{"username": "secretuser", "password": "secretpass"}'
    }

    with patch("app.config.boto3.client", return_value=fake_secretsmanager) as mock_client:
        settings = Settings(
            database_host="db.example.com",
            database_port=5432,
            database_name="booking",
            database_secret_arn="arn:aws:secretsmanager:us-east-1:123456789012:secret:rds!db-fake",
            aws_region="us-east-1",
        )

        url = settings.database_url

    assert url == (
        "postgresql+psycopg2://secretuser:secretpass@db.example.com:5432/booking"
    )
    mock_client.assert_called_once_with("secretsmanager", region_name="us-east-1")
    fake_secretsmanager.get_secret_value.assert_called_once_with(
        SecretId="arn:aws:secretsmanager:us-east-1:123456789012:secret:rds!db-fake"
    )
