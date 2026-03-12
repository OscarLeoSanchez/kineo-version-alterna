from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import User


class UserRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_email(self, email: str) -> User | None:
        statement = select(User).where(User.email == email)
        return self.db.scalar(statement)

    def create_user(self, *, email: str, password_hash: str, full_name: str) -> User:
        user = User(
            email=email,
            password_hash=password_hash,
            full_name=full_name,
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def update_full_name(self, *, user_id: int, full_name: str) -> User:
        user = self.db.get(User, user_id)
        if user is None:
            raise ValueError("User not found")

        user.full_name = full_name
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user
