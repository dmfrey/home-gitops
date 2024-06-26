import os
import json
import time
from typing import Optional
from urllib.request import Request, urlopen
from urllib.error import URLError


class EMQXManager:
    def __init__(
        self,
        emqx_address: str,
        admin_username: str,
        admin_password: str,
    ) -> None:
        self.emqx_address = emqx_address
        self.admin_username = admin_username
        self.admin_password = admin_password

    def wait_for_emqx(self) -> None:
        while True:
            try:
                response = urlopen(f"http://{self.emqx_address}/api/v5/status")
                if response.getcode() == 200:
                    print("EMQX started, ready to initialize..")
                    break
            except URLError:
                print("Waiting for EMQX to start..")
                time.sleep(5)

    def get_api_token(self) -> Optional[str]:
        data = json.dumps(
            {"username": self.admin_username, "password": self.admin_password}
        ).encode("utf-8")
        req = Request(
            f"http://{self.emqx_address}/api/v5/login",
            data=data,
            headers={"Content-Type": "application/json"},
        )
        try:
            with urlopen(req) as response:
                response_data = json.loads(response.read().decode("utf-8"))
                return response_data.get("token", None)
        except URLError as e:
            print(f"Error: {e}")
            return None

    def create_mqtt_user(self, api_token: str, username: str, password: str) -> bool:
        data = json.dumps(
            {
                "user_id": username,
                "password": password,
                "is_superuser": True,
            }
        ).encode("utf-8")
        headers = {
            "Authorization": f"Bearer {api_token}",
            "Content-Type": "application/json",
        }
        req = Request(
            f"http://{self.emqx_address}/api/v5/authentication/password_based:built_in_database/users",
            data=data,
            headers=headers,
        )
        try:
            with urlopen(req) as response:
                return response.getcode() == 200
        except URLError as e:
            print(f"Error: {e}")
            return False

def discover_services():
    """Discover all services based on environment variable naming convention."""
    services = set()
    for key in os.environ:
        if key.startswith("X_EMQX_USERNAME"):
            service = key[16:]  # Extract the service name after the prefix
            services.add(service)
    return services


def main() -> None:
    emqx_address = os.getenv("X_EMQX_ADDRESS")
    admin_username = os.getenv("EMQX_DASHBOARD__DEFAULT_USERNAME")
    admin_password = os.getenv("EMQX_DASHBOARD__DEFAULT_PASSWORD")
    services = discover_services()

    if not all(
        [emqx_address, admin_username, admin_password]
    ):
        print("Missing environment variables.")
        return

    emqx_manager = EMQXManager(
        emqx_address, admin_username, admin_password
    )
    emqx_manager.wait_for_emqx()

    api_token = emqx_manager.get_api_token()
    if api_token:
        for service in services:
            username = os.getenv(f"X_EMQX_USERNAME_{service}")
            password = os.getenv(f"X_EMQX_PASSWORD_{service}", None)

            success = emqx_manager.create_mqtt_user(api_token, username, password)
        if success:
            print(f"User {username} created successfully.")
        else:
            print(f"Error creating user {username} or user already exists.")
    else:
        print("Login failed.")

    while True:
        time.sleep(1)


if __name__ == "__main__":
    main()
