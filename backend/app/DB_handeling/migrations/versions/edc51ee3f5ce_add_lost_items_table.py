"""add lost_items table

Revision ID: edc51ee3f5ce
Revises: 9773444ebcdb
Create Date: 2026-04-17 16:41:08.280999

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'edc51ee3f5ce'
down_revision: Union[str, Sequence[str], None] = '9773444ebcdb'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
   pass


def downgrade() -> None:
    op.drop_table('lost_items')