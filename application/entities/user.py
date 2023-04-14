from flask_login import UserMixin


class User(UserMixin):
    sub: str = None
    email_verified: bool = None
    email: str = None

    def __init__(self, id: str, confirmed: str):
        self.id: str = id
        self.confirmed: bool = confirmed

    @property
    def is_active(self) -> bool:
        return self.confirmed
