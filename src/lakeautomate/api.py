import hmac
import os

from fastapi import FastAPI, Header, HTTPException

from lakeautomate.homeassistant import HomeAssistantClient, HomeAssistantError

app = FastAPI(
    title="LakeAutomate API",
    description="Local control and telemetry API for the Levenson Lake property.",
    version="0.1.0",
)


def require_api_key(x_api_key: str | None) -> None:
    expected = os.getenv("LAKE_API_KEY")

    if not expected:
        raise HTTPException(
            status_code=503,
            detail="LakeAutomate API authentication is not configured.",
        )

    if not x_api_key or not hmac.compare_digest(x_api_key, expected):
        raise HTTPException(status_code=401, detail="Unauthorized")


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "service": "LakeAutomate",
        "status": "ok",
    }


@app.get("/api/ha/entity/{entity_id}")
def get_home_assistant_entity(entity_id: str) -> dict:
    try:
        client = HomeAssistantClient()
        entity = client.get_entity(entity_id)
    except HomeAssistantError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    return {
        "entity_id": entity.get("entity_id"),
        "state": entity.get("state"),
        "attributes": entity.get("attributes", {}),
        "last_changed": entity.get("last_changed"),
        "last_updated": entity.get("last_updated"),
    }


@app.post("/api/ha/light/{entity_id}/{action}")
def control_light(
    entity_id: str,
    action: str,
    x_api_key: str | None = Header(default=None),
) -> dict[str, str]:
    require_api_key(x_api_key)

    if not entity_id.startswith("light."):
        raise HTTPException(status_code=400, detail="Entity must be a light.")

    if action not in {"turn_on", "turn_off"}:
        raise HTTPException(
            status_code=400,
            detail="Action must be turn_on or turn_off.",
        )

    try:
        client = HomeAssistantClient()
        client.call_service(
            domain="light",
            service=action,
            data={"entity_id": entity_id},
        )
    except HomeAssistantError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    return {
        "status": "ok",
        "entity_id": entity_id,
        "action": action,
    }
