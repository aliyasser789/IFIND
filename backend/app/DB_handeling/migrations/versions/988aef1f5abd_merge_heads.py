"""merge heads

Revision ID: 988aef1f5abd
Revises: da34f1c61f65, edc51ee3f5ce
Create Date: 2026-04-18 14:03:18.928744

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '988aef1f5abd'
down_revision: Union[str, Sequence[str], None] = ('da34f1c61f65', 'edc51ee3f5ce')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
