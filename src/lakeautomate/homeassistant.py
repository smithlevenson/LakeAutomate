import os
from typing import Any

import requests


class HomeAssistantError(RuntimeError):
    """Raised when Home Assistant cannot satisfy a request."""


class HomeAssistantClient:
    def __init__(self) -> None:
        self.base_url = os.getenv("LAKE_HA_URL", "http://10.2.0.11").rstrip("/")
        self.token = os.getenv("LAKE_HA_TOKEN")

        if not self.token:
            raise HomeAssistantError(
                "LAKE_HA_TOKEN environment variable is not configured."
            )

        self.session = requests.Session()
        self.session.headers.update(
            {
                "Authorization": f"Bearer {self.token}",
                "Content-Type": "application/json",
            }
        )

    def get_entity(self, entity_id: str) -> dict[str, Any]:
        url = f"{self.base_url}/api/states/{entity_id}"

        try:
            response = self.session.get(url, timeout=10)
        except requests.RequestException as exc:
            raise HomeAssistantError(
                f"Unable to reach Home Assistant: {exc}"
            ) from exc

        if response.status_code == 404:
            raise HomeAssistantError(f"Entity not found: {entity_id}")

        try:
            response.raise_for_status()
        except requests.RequestException as exc:
            raise HomeAssistantError(
                f"Home Assistant returned HTTP {response.status_code}"
            ) from exc

        return response.json()

    def call_service(
        self,
        domain: str,
        service: str,
        data: dict[str, Any],
    ) -> Any:
        url = f"{self.base_url}/api/services/{domain}/{service}"

        try:
            response = self.session.post(url, json=data, timeout=10)
            response.raise_for_status()
        except requests.RequestException as exc:
            raise HomeAssistantError(
                f"Home Assistant service call failed: {exc}"
            ) from exc

        return response.json()
