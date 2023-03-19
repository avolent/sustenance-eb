from flask_login import UserMixin

class User(UserMixin):
    def __init__(self, id, confirmed):
        self.id = id
        self.confirmed = confirmed

    @property
    def is_active(self):
        return self.confirmed
