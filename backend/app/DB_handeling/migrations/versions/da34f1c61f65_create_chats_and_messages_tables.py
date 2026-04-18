"""create chats and messages tables

Revision ID: da34f1c61f65
Revises: 9773444ebcdb
Create Date: 2026-04-17 10:17:46.212610

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'da34f1c61f65'
down_revision: Union[str, Sequence[str], None] = '9773444ebcdb'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table('chats',
        sa.Column('id', sa.UUID(as_uuid=True), primary_key=True),
        sa.Column('item_id', sa.UUID(as_uuid=True), sa.ForeignKey('found_items.id'), nullable=True),
        sa.Column('finder_id', sa.UUID(as_uuid=True), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('claimer_id', sa.UUID(as_uuid=True), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )
    op.create_table('messages',
        sa.Column('id', sa.UUID(as_uuid=True), primary_key=True),
        sa.Column('chat_id', sa.UUID(as_uuid=True), sa.ForeignKey('chats.id'), nullable=True),
        sa.Column('sender_id', sa.UUID(as_uuid=True), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('sent_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
    )


def downgrade() -> None:
    op.drop_table('messages')
    op.drop_table('chats')