from sqlalchemy.orm import DeclarativeBase

# All database models will inherit from this Base class
# Think of it as the parent template every table is built on
class Base(DeclarativeBase):
    pass